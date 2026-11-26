# Review: Platform-aware design gates and Swift standards

**Track:** `platform-design-swift_20261125`
**Range:** `b589fb6044b80647918cc05d5b43c7cf695e6542..b83cf3f`
**State:** Awaiting review; no closure, fixes, or review commits performed.
**Verdict:** Changes requested — one High finding blocks finalization.

## Plan Compliance

All four completed tasks have corresponding implementation commits and expected
file changes. All three phase checkpoints reference real task commits and have
verification git notes. The worktree branch, metadata, registry entry, and
awaiting-review note agree.

| Task | Commit | Observed implementation |
| --- | --- | --- |
| Design planning and optional handoff | `7d3f74b` | Canonical contract; setup installation/init handoff; pre-specification design checkpoint and track-local brief |
| Swift guidance | `a6bf5e3` | Bundled Swift guide; stack-specific setup recommendations and formatter discovery |
| Implementation/review evidence | `8685d3f` | Approved-design consumption; platform-specific evidence and closure guard; README |
| Installer verification | `4fee211` | Isolated installation/reinstallation smoke test |

The user-approved `documentation` classification is a track-local exception,
not an unapproved change to the global workflow. The installer test remains
`e2e-flow`. No application, extra command, mandatory skill dependency, or
automatic formatting was introduced.

**Exception:** The initialization and design records are not reliably carried
across the worktree boundary. See H1 under Code Quality. This undermines reuse
of confirmed context and references despite the individual task files existing.

### Scenario walkthrough evidence

These are **instruction/source walkthroughs**, not executions of the consuming
agent or an actual web/mobile app. “Pass” below means the specified instruction
route is present and consistent for that scenario, not that autonomous agent
compliance has been demonstrated.

Evidence shorthand:

- **S:** `.opencode/command/setup.md:94–141` — optional integration.
- **N:** `.opencode/command/new-track.md:63–123` — design checkpoint.
- **W:** `.opencode/command/setup.md:82–92,145–172` and
  `conductor/assets/code_styleguides/swift.md:7–75` — Swift selection and policy.
- **I:** `.opencode/command/implement.md:31–48` — approved design consumption.
- **R:** `.opencode/command/review.md:45–50,64–118,159–162` — evidence and closure.

| Scenario/input | Expected result | Observed route and assessment |
| --- | --- | --- |
| Web, skill available and initialized | Use planning-only `shape` | N; Pass |
| Skill absent | Offer assisted installation, instructions, or direct planning | S steps 1–3 and N; Pass |
| Installation accepted | Explain exact command/source/scope/effects and obtain approval before execution | S step 2; Pass |
| Installation declined | Finish setup; direct planning remains available | S steps 2–3 and closing paragraph; Pass |
| Installer fails | Do not claim availability or block setup | S step 3 and closing paragraph; Pass |
| Official instructions unavailable | Do not guess a command; offer official link/fallback | S step 2; Pass |
| Installation succeeds but discovery needs restart | Recheck discovery, finish setup, defer init | S step 3; Pass |
| Setup initialization accepted | Reuse approved context, preserve confirmation, verify product record | S steps 4–7; local handoff present, end-to-end worktree transfer fails H1 |
| Initialization skipped | Finish setup; offer relevant first-use handoff later | S steps 5–7 and N; Pass |
| Initialization declined | No repeated offer within the conversation; direct brief | S closing paragraph and N; Pass |
| First-use init during new-track | Initialize before shape and keep context accessible in the track | N web route; prerequisite present, worktree transfer fails H1 |
| Valid existing PRODUCT.md | Reuse rather than reinterview/overwrite | S step 4; Pass for already committed records; new/uncommitted records affected by H1 |
| Conflicting/stale product facts | Ask for reconciliation, preserve existing content | S steps 4 and 7; Pass for reconciliation instructions |
| Missing/incomplete product record after init | Do not substitute notes or proceed as initialized | S step 7 and N prerequisites; Pass |
| Approved external design | Summarize decisions, link source, ask only about gaps | N applicability; Pass |
| Design alternatives selected | Wait for user choice and record confirmed brief | N user-control/brief sections; Pass, subject to reference portability H1 |
| User requests revisions | Return to choices rather than silently proceed | N user-control section; Pass |
| Requirements approved but no direction selected | Do not treat requirements approval as visual approval | N user-control section; Pass |
| Selection explicitly delegated | Allow agent choice and record provenance | N user-control section; Pass |
| Preview tooling unavailable | Explain limitation; supported alternative, not fabricated preview | N user-control section; Pass |
| Native iOS | Apple HIG; no automatic Impeccable invocation | N native route; Pass |
| Native Android | Android guidance; no automatic Impeccable invocation | N native route; Pass |
| Shared framework targets both native platforms | Shared intent with per-platform behavior; not web by framework name | N cross-platform route; Pass |
| Backend/tooling-only work | Record not applicable; no design exercise | N applicability; Pass |
| Established-component label correction | Short justification; preserve incumbent direction | N applicability/user-control; Pass |
| New Swift project without formatter config | Prefer swift-format and confirm configuration/check command | W formatter policy and stack-matching guide selection; Pass at instruction level |
| Existing formatter/configuration | Preserve tool and config, distinguish similarly named tools | W; Pass |
| Swift-only library | Swift guidance independent of native UI | W; Pass |
| Kotlin-only Android app | Existing Android matrix, no Swift based on platform alone | W; Pass |
| Cross-platform app without project-owned Swift | Do not recommend Swift solely for iOS targeting | W; Pass |
| Mixed app with project-owned Swift module | Recommend Swift plus genuinely present languages | W; Pass |
| Formatter unavailable | Report not verified; no silent install or reformat | W and R; Pass |
| Legacy/non-UI track lacks design.md | No retroactive design requirement | I and R; Pass |
| Newly approved plan requires missing brief | Stop and recover approved decisions, not invent new direction | I; Pass |
| Native app has only browser preview | Do not count preview as native evidence | R platform table; Pass |
| Device/emulator unavailable | Report not verified; required criterion remains blocking | R; Pass |
| Screen-reader behavior untested | Source/screenshots cannot establish runtime accessibility | R; Pass |
| Required criterion fails | No closure until resolved or explicitly revised | R; Pass |
| User explicitly revises criterion | Reconcile affected records and re-evaluate | R; Pass |
| Implementation deviates from selected direction | Report noncompliance; no silent replacement | I and R; Pass |

## Code Quality

### [High] H1 — Initialized context can be left behind when the track worktree is created

**Locations:** `.opencode/command/setup.md:125–135,251–253`;
`.opencode/command/new-track.md:26–28,79–88,194–224`.

**Failure path:**

1. A user accepts web initialization during setup. Impeccable creates root
   `PRODUCT.md` and potentially `.impeccable/config.json` or other approved
   durable records.
2. Setup's commit stages only `conductor/`. It does not ensure the new
   integration records are committed or explicitly transferred.
3. `new-track` creates a worktree from committed `HEAD` and moves all subsequent
   work there. Untracked records and uncommitted changes are not inherited.
4. The consuming track can therefore lack its confirmed product record,
   configuration choices, or selected design's supporting local references.
   First-use initialization and decision artifacts produced before worktree
   creation have the same issue.

The installed Impeccable init reference tells the user which files to commit,
but does not commit them; relying on that reminder does not define a reliable
Conductor handoff. The files remain in the original checkout, not necessarily
deleted, but they are unavailable at the destination where execution continues.

**Reproduction:** In a disposable Git repository under the approved scratch
directory, commit a baseline, create untracked `PRODUCT.md` and
`.impeccable/config.json`, then run `git worktree add -b track/reproduction
<destination>`. The destination contains the committed baseline but neither new
file. This reproduction used synthetic content only and did not run Impeccable,
modify this checkout, or touch real user configuration.

**Impact/severity:** The independent reviewer rated the integration gap Medium.
This report grades it High because a normal newly initialized web-project path
cannot reliably carry the approved product/design inputs into its default
implementation worktree. It breaks the intended setup-to-track integration,
not merely polish. All packaging tests can pass while this handoff fails.

**Recommended correction:** Define explicit handling at the worktree boundary.
With appropriate consent, either commit the approved durable integration
records before branching, or transfer an explicit set into the new worktree
and verify their contents and reference resolution there. Preserve unrelated
changes and existing files; do not indiscriminately commit/copy ignored runtime
data, machine-local configuration, secrets, or all of `.impeccable/`.
Handle both setup-time and first-use initialization, plus selected local
preview/reference paths. Add a disposable-repository regression for the chosen
handoff behavior.

No other substantive new logic issue identified. The installer test uses a
fresh temporary HOME, quotes paths including spaces, cleans only its owned
temporary directory, and verifies repeat installation and unrelated-config
preservation.

## Style/Guidelines

**Clean.** Changed files follow the selected general guide's readability,
consistency, simplicity, and explanatory-comment principles. Swift guidance
separates API naming principles, formatting choices, and project engineering
policy. No repository-wide linter is configured; no lint compliance beyond
the actual checks below is claimed.

## Security

**Clean for the reviewed changes.** No added credentials, API keys, plaintext
secrets, or PII logging identified. The installer smoke test passes a temporary
HOME to the real installer and confines deliberately corrupted files and
cleanup to its fresh temporary directory. Assisted-install instructions require
verification of the official source and explicit command/scope approval.
No real Impeccable installation, remote installer execution, or user-level
configuration modification occurred during review.

## Test Results

Fresh runs in this review:

| Check | Result |
| --- | --- |
| `sh conductor/scripts/test-installer.sh` | PASS — isolated install/reinstall; lifecycle/Swift/helper assets and workflow marker; unrelated configuration preserved |
| `sh conductor/scripts/test-open-pr.sh` | PASS — dispatcher regression suite |
| `sh conductor/scripts/test-archive-track.sh` | PASS — archive safety suite |
| `sh -n conductor/scripts/test-installer.sh` | PASS — shell syntax |
| `git diff --check b589fb6..HEAD` | PASS — whitespace |
| Completed-task commits and phase notes | PASS — all task files and checkpoint evidence present |
| Synthetic Git initialization/worktree reproduction | H1 reproduced — uncommitted integration records absent from destination |

All three repository test scripts were discovered and run, with TMPDIR set to
the approved scratch directory. Passing packaging/regression tests do not
cover the missing initialization/worktree transfer.

## Design/Platform Evidence

**Actual application UI/device checks: not applicable.** This track changes
workflow tooling and documentation, not an application surface; the approved
plan explicitly excludes creating an app or requiring a design artifact for
this tooling track. No `PRODUCT.md` was initialized here.

**Autonomous host-agent compliance: not verified.** The user-approved
documentation-task policy uses source/scenario walkthroughs. This report
does not substitute them for real browser, simulator, assistive-technology,
or host-agent execution.

## Independent Review and Scope

A fresh-context read-only reviewer independently identified H1. Its report
was checked against source and the disposable Git reproduction.

Items not used as grounds for speculative findings:

- Actual app/device behavior: no app was changed; out of this track's approved scope.
- Autonomous agent behavior: not exercised; explicitly distinguished from
  documentation walkthroughs rather than assumed correct.
- Pre-existing skip-hatch approval behavior independent of integration records:
  not introduced by this track; the new design checkpoint itself still applies.

## Approval Gate

Recommend fixing H1 before finalization. The track remains awaiting review.
No fixes were applied, no commits were made, and registry/metadata were not
changed during this review. A general finalization approval does not silently
waive the broken context handoff; resolution or an explicit approved requirement
revision is needed before closure.

## H1 Resolution Addendum

**Status:** Fix implemented; awaiting final re-review and user approval.

The worktree boundary now has a read-only checker,
`conductor/scripts/check-design-context.py`. It accepts only explicitly
selected project-relative files, rejects symlinks/path escapes and known
private/runtime paths, and verifies each file matches both the index and
`HEAD`. It does not stage, commit, copy, overwrite, or print file contents.
The installer publishes it as an asset.

Setup instructions require explicit consent before including a narrowly
selected set of durable integration records in its commit. New-track instructions
require a pre-branch check, a user-approved selective-commit decision when
needed, and destination verification. README and canonical doctrine describe
the same boundary. Temporary previews and broad runtime/config directories are
not implicitly carried.

Fresh verification after the fix:

| Check | Result |
| --- | --- |
| `python3 conductor/scripts/test-design-context.py` | PASS — 7 cases, including committed files surviving a new worktree and untracked/staged/unstaged/private/missing/unsafe inputs being rejected |
| `sh conductor/scripts/test-installer.sh` | PASS — checker is included in isolated install and reinstall |
| `sh conductor/scripts/test-open-pr.sh` | PASS |
| `sh conductor/scripts/test-archive-track.sh` | PASS |
| `git diff --check` | PASS |
| `sh -n install.sh conductor/scripts/test-installer.sh` | PASS |
| Python bytecode compilation for checker and tests | PASS |

The original H1 failure is covered by a real disposable Git worktree test:
committed selected context appears byte-for-byte in the destination, while
unrelated untracked content does not. Uncommitted selected files fail the
checker without modifying repository status. I did not run a consuming host
agent or real application scenario; those remain outside the evidence claimed.
The track remains awaiting review; no closure or final approval is implied.
