#!/usr/bin/env python3
"""Regression tests for the approved-context boundary before track branching."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


HELPER = Path(__file__).with_name("check-design-context.py").resolve()


class DesignContextTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="test-design-context-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.repo = self.base / "source with spaces"
        self.repo.mkdir()
        self.git("init", "-q")
        self.write("baseline.md", "committed baseline\n")
        self.commit("baseline.md")

    def git(self, *args):
        return subprocess.run(
            ["git", "-C", str(self.repo), *args],
            check=True, capture_output=True, text=True,
        ).stdout.strip()

    def write(self, name, content):
        target = self.repo / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)

    def commit(self, *paths):
        self.git("--literal-pathspecs", "add", "--", *paths)
        self.git(
            "-c", "user.name=Context Test",
            "-c", "user.email=context-test@example.invalid",
            "commit", "-qm", "fixture context",
        )

    def check_context(self, *paths, cwd=None):
        return subprocess.run(
            [sys.executable, str(HELPER), "--", *paths],
            cwd=cwd or self.repo, capture_output=True, text=True,
        )

    def test_committed_context_survives_new_worktree(self):
        paths = (
            "PRODUCT.md", ".impeccable/config.json",
            "conductor/design-references/chosen [one].svg",
        )
        for name in paths:
            self.write(name, f"approved fixture: {name}\n")
        self.commit(*paths)
        self.write("unrelated.txt", "leave this untracked\n")
        before = self.git("status", "--porcelain")
        ready = self.check_context(*paths)
        self.assertEqual(ready.returncode, 0, ready.stderr)
        self.assertIn("PASS:", ready.stdout)
        self.assertEqual(self.git("status", "--porcelain"), before)
        target = self.base / "track with spaces"
        self.git("worktree", "add", "-b", "track/design", str(target))
        for name in paths:
            self.assertEqual((target / name).read_bytes(), (self.repo / name).read_bytes())
        self.assertFalse((target / "unrelated.txt").exists())
        self.assertEqual(self.check_context(*paths, cwd=target).returncode, 0)

    def test_untracked_context_blocks_without_mutation(self):
        self.write("PRODUCT.md", "new product\n")
        before = self.git("status", "--porcelain")
        result = self.check_context("PRODUCT.md")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not committed unchanged at HEAD", result.stderr)
        self.assertEqual(self.git("status", "--porcelain"), before)

    def test_unstaged_and_staged_context_both_block(self):
        self.write("PRODUCT.md", "approved v1\n")
        self.commit("PRODUCT.md")
        for staged in (False, True):
            with self.subTest(staged=staged):
                self.write("PRODUCT.md", "approved v2\n")
                if staged:
                    self.git("add", "PRODUCT.md")
                before = self.git("status", "--porcelain")
                result = self.check_context("PRODUCT.md")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("not committed unchanged at HEAD", result.stderr)
                self.assertEqual(self.git("status", "--porcelain"), before)

    def test_missing_reference_blocks(self):
        result = self.check_context("missing.svg")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not a regular file", result.stderr)

    def test_private_and_runtime_records_are_rejected_even_if_committed(self):
        for name in (
            ".impeccable/config.local.json", ".impeccable/questions/answer.json",
            ".impeccable/mocks/decision/chosen.png", ".env", ".env.production",
        ):
            with self.subTest(name=name):
                self.write(name, "private or temporary fixture\n")
                self.commit(name)
                result = self.check_context(name)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("private or runtime", result.stderr)

    def test_symlink_and_path_escape_are_rejected(self):
        self.write("PRODUCT.md", "approved\n")
        os.symlink("PRODUCT.md", self.repo / "alias.md")
        self.commit("PRODUCT.md", "alias.md")
        result = self.check_context("alias.md")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("symlink", result.stderr)
        for name in ("../outside.md", str(self.repo / "PRODUCT.md"), "."):
            with self.subTest(name=name):
                result = self.check_context(name)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("project-relative file", result.stderr)

    def test_requires_explicit_files(self):
        result = self.check_context()
        self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
