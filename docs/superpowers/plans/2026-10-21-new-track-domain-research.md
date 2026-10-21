# `/new-track` Domain Modeling and Research Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a domain-language/scenario pass and conditional primary-source research guidance to `/new-track` without adding wayfinder-style scope routing.

**Architecture:** Extend the existing brainstorming protocol in `.opencode/command/new-track.md`. The domain pass sharpens ambiguous terminology before fork resolution; the research guidance resolves factual prerequisites only when a fork depends on external or repository evidence. No new runtime dependency or artifact type is introduced.

**Tech Stack:** Markdown command protocol, POSIX shell-based static checks.

**Spec:** `docs/superpowers/reports/2026-10-20-matt-pocock-skills-new-track-analysis.md`

## Global Constraints

- Keep `/new-track` focused on brainstorming and approved track creation.
- Do not add a wayfinder-style size check, scope decomposition, or routing flow.
- Preserve one-question-at-a-time interaction.
- Preserve the existing fact/decision classification, frontier guidance, approval gates, provenance sections, and no-auto-start `/implement` rule.
- Prefer repository evidence and primary documentation for factual research.
- Do not create a glossary or research report for every track.

## Review Focus

- Domain terms with multiple meanings must be clarified through concrete scenarios before they become acceptance criteria.
- Existing project terminology must take precedence over a newly invented synonym.
- Research must resolve factual prerequisites without silently deciding product or scope preferences.
- Conflicting or unavailable sources must become explicit uncertainty for the user, not an agent assumption.
- No wayfinder wording or oversized-effort routing should be introduced accidentally.

---

### Task 1: Add the domain-language and scenario pass

**Files:**
- Modify: `.opencode/command/new-track.md`
- Test: temporary ignored static harness

**Interfaces:**
- Consumes: the draft understanding and existing project terminology.
- Produces: clarified terminology and scenario-tested meanings used by the later fork checklist.

- [x] **Step 1: Write the failing static assertions**

Require wording that instructs the agent to identify ambiguous domain terms, compare them with project terminology, and use concrete scenarios to clarify behavior.

- [x] **Step 2: Run the assertions and verify RED**

The assertions must fail against the current command before editing.

- [x] **Step 3: Add the minimal domain-language protocol**

Place it after the initial draft understanding and before fork classification. State that only behavior- or scope-relevant ambiguity requires a user question, and that ordinary tracks do not automatically create glossary artifacts.

- [x] **Step 4: Run the assertions and verify GREEN**

Confirm the new protocol exists and the existing one-question, approval, and no-auto-start guards remain present.

---

### Task 2: Add conditional primary-source research guidance

**Files:**
- Modify: `.opencode/command/new-track.md`
- Test: temporary ignored static harness

**Interfaces:**
- Consumes: `FACT` and `MIXED` fork classifications plus the domain pass's clarified questions.
- Produces: factual prerequisites resolved through repository evidence or primary documentation, with material sources preserved in the draft spec.

- [x] **Step 1: Write the failing static assertions**

Require wording that limits research to factual prerequisites, prefers primary documentation, records material sources, and exposes conflicting or unavailable evidence as user-owned uncertainty.

- [x] **Step 2: Run the assertions and verify RED**

The assertions must fail against the current command before editing.

- [x] **Step 3: Add the minimal conditional research protocol**

Extend the existing `FACT`/`MIXED` rules rather than creating a separate research workflow. Make clear that research informs a decision but does not silently make it, and that small lookups do not require a separate report.

- [x] **Step 4: Run the full static verification**

Run the new assertions, existing protocol guards, `git diff --check`, and inspect the diff for accidental wayfinder or scope-routing language.

---

## Self-review

- The two improvements stay in the existing command document.
- The wayfinder-style flow is explicitly excluded.
- No new command, skill, dependency, or artifact schema is required.
- The existing fact/decision/frontier protocol remains the basis for research ordering.
