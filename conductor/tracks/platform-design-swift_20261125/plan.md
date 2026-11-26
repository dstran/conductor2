# Platform-aware Design Gates and Swift Standards Implementation Plan

> Execute through `/conductor/implement platform-design-swift_20261125` only
> after plan approval and task classification. Conductor owns execution,
> task commits, phase checkpoints, and the separate review handoff.

**Goal:** Add platform-aware design planning and review, with optional
Impeccable for web and a separately selected Swift code-style guide.

**Architecture:** Keep doctrine in `skill/SKILL.md` and operational instructions
in the existing lifecycle commands. Use the existing guide asset installer;
do not vendor Impeccable or add a parallel lifecycle.

**Tech stack:** Markdown commands and assets; shell regression tests.

**Spec:** [Approved specification](./spec.md).

## Global constraints

- Keep `setup → new-track → implement → review` unchanged.
- No new top-level command, mandatory design dependency, automatic reformatting,
  or implementation of an actual app.
- Do not install Impeccable automatically or invoke it for native work unless requested.
- `spec.md` remains requirements authority; `plan.md` incorporates the approved design work.
- Preserve existing formatting tools and configuration.
- Report unavailable checks as **not verified**, never as passes.
- Missing evidence for a required acceptance criterion prevents closure until
  resolved or explicitly revised with approval.
- Do not create new doctrine mirrors or design tools. This tooling track does
  not create its own `PRODUCT.md`; consumer web projects may opt into the
  Impeccable-owned product record described in the specification.
- Impeccable initialization requires explicit opt-in, reuses approved Conductor
  context, and preserves existing product files and configuration consent.
- Assisted Impeccable installation requires explicit approval of its command,
  source, scope, and configuration effects. Verify session discovery afterward;
  a required restart defers initialization without blocking Conductor setup.

## Classification blocker

The existing workflow does not classify documentation-only changes. Tasks 1–3
are marked `[needs classification]` as required by `conductor/workflow.md`.
Before implementation, ask the user to classify these tasks and confirm the
verification policy. Proposed track-local classification: `documentation`,
verified by the specified source checks and scenario walkthroughs, without
inventing executable tests for prose. This proposal is not yet approved and
does not change the global taxonomy.

## Review focus

- Backend-only tracks and established-pattern fixes must not acquire a mandatory
  design interview or Impeccable dependency (Task 1 scenarios).
- Cross-platform frameworks must route by deployment platform, not language or
  framework name; a browser preview does not verify native behavior (Tasks 1 and 3).
- External designs and existing product context must be reused, with no competing
  requirements document or duplicate discovery interview. Existing `PRODUCT.md`
  conflicts need explicit reconciliation; skipped setup must still support
  first-use initialization (Task 1 scenarios).
- Existing SwiftFormat/SwiftLint/formatter configuration must not be overwritten
  or confused with `swiftlang/swift-format` (Task 2 scenarios).
- Unavailable devices, accessibility tools, or formatter executables must not
  produce a pass or silently waive a required acceptance criterion (Task 3 scenarios).

## Phase 1: Design planning and Swift standards

- [ ] Task: Integrate platform-aware design planning into canonical doctrine and new-track [needs classification]

  **Files:** Modify `skill/SKILL.md`, `.opencode/command/new-track.md`,
  and `.opencode/command/setup.md`.
  **Consumes:** Existing brainstorming, specification approval (Gate A), and
  plan approval sequence.
  **Produces:** An optional assisted installation and web initialization handoff during setup and a
  first-use fallback; a design decision checkpoint before Gate A; track-local
  `design.md` persisted only when applicable after approval, alongside the
  existing spec/plan/metadata artifacts.

  1. Read the three files and the approved spec. Add a concise canonical contract
     for material UI design decisions; put operational detail in `new-track`.
  2. Route web to available Impeccable `shape` or a direct equivalent brief;
     route iOS/Android to their current official guidance. Detect availability
     through the host's skill discovery, not a hard-coded home directory.
     Never install a missing skill automatically. Native use requires an explicit request.
     If unavailable for a consuming web project, offer "Install with approval",
     "Show instructions", or "Continue without it". Consult current official
     installation instructions at `https://impeccable.style/`; explain the
     exact command, source, target agent, project-local/global scope, and effects
     on existing configuration before obtaining approval to run it. If the
     instructions cannot be verified or execution is unavailable, say so and
     provide the official link or continue without it; never guess a command.
     Recheck host skill discovery after installation. A successful installer
     exit or a file on disk does not establish current-session availability.
     If a restart is needed, finish Conductor setup and defer `init` until the
     skill is discoverable. Installation refusal or failure also permits setup
     completion and the direct design-brief fallback.
     Consult the installed skill's current `init` and `shape` references rather
     than assuming command behavior from their names.
     In setup, offer `/impeccable init` for web projects after product context
     and tech stack approval, before completion. Run only with explicit opt-in;
     absence or refusal does not block Conductor setup.
     Use one structured question: "Initialize Impeccable for this web project?"
     with "Initialize now (Recommended)" and "Skip for now". Explain that the
     first reuses approved context and asks only about gaps, while the second
     finishes setup and defers the offer to a relevant web design track.
     A positive answer hands off to the available skill's `init` workflow,
     not a shell command or an installation step. A valid existing product
     record is reused rather than triggering a redundant initialization offer.
     Feed it the approved Conductor context, reuse settled answers, and ask only
     about material gaps or conflicts. Honor the skill's confirmations and
     separate consent for configuration changes; do not auto-select visual or
     workflow preferences. `init` does not create `DESIGN.md`.
     If deferred, offer initialization before the first web design track that
     needs it. Before using Impeccable's new-design `shape` flow, verify its
     resolved `PRODUCT.md` exists and contains the confirmed product record.
     Reuse an existing valid record; reconcile stale or conflicting facts with
     approval, never silent replacement. Link applicable Conductor sources and
     keep that derived record aligned without giving it independent requirements
     authority. If the user declines or initialization cannot complete, use a
     direct design brief instead; do not bypass the skill's prerequisites.
  3. Reuse already answered discovery questions and approved external artifacts.
     The brief records task/audience, flow, significant states, layout intent,
     platform behavior, accessibility, references, and acceptance criteria.
     Summarize an external artifact's approved decisions and link it rather
     than requiring readers to reconstruct requirements from an inaccessible URL.
  4. Backend-only work records design as not applicable; established-pattern
     fixes record their justification in the specification without a new brief.
     Do not require this tooling-only track itself to produce a UI design.
  5. Incorporate design consequences into the specification before approval
     and into plan tasks before plan approval. Material later design changes
     require reconciliation and approval, not silent scope expansion.
   6. Walk scenarios: web skill present; absent; assisted installation accepted;
     declined; failed; instructions unavailable; installation succeeds but
     discovery requires restart; setup init accepted; skipped;
     declined; first-use init after skipped setup; existing valid `PRODUCT.md`;
     conflicting product facts; missing/incomplete product record after init;
     approved external design;
     iOS-only; Android-only; shared mobile framework targeting both platforms;
     backend-only; label correction using an existing component.
     Assert correct routing, no duplicate interview, no silent file overwrite,
     no installation before command/scope approval, no implicit configuration
     consent, no `init` before skill discovery, no `shape` before required initialization,
     and no coding before approval. Confirm setup can finish when init is skipped
     and a direct design brief remains available when Impeccable cannot be used.
  7. Run `git diff --check`; inspect the existing lifecycle gates for preserved
     approval ordering. Commit task files, then update this plan separately
     using the task commit procedure.

- [ ] Task: Bundle Swift guidance and integrate stack-specific setup selection [needs classification]

  **Files:** Create `conductor/assets/code_styleguides/swift.md`;
  modify `.opencode/command/setup.md`.
  **Consumes:** Existing guide selection/copying and verification-command discovery.
  **Produces:** A selectable `swift` guide distributed by the installer's
  existing asset glob, plus confirmed formatter checks in project tech context.

  1. Check current primary sources: Swift API Design Guidelines at
     `https://www.swift.org/documentation/api-design-guidelines/` and
     `https://github.com/swiftlang/swift-format`.
  2. Write a concise guide with source links covering clear call sites, naming,
     argument labels, mutating/nonmutating conventions, and documentation.
     Separate source-based guidance from explicitly identified project choices;
     do not prescribe a new app architecture or universal concurrency policy.
  3. Document that formatter defaults are not an official universal Swift style.
     Preserve established tools and configuration. Prefer `swiftlang/swift-format`
     only when no formatter is established; do not confuse it with similarly
     named tools. Confirm availability and syntax before recording a lint command;
     its strict lint mode must fail on warnings when used as an enforcement check.
  4. Add `swift` to setup's available guides and recommend `general` plus `swift`
     for confirmed Swift source, regardless of whether there is an iOS UI.
     Leave existing Android selection intact. Do not select Swift solely because
     a Flutter/React Native app targets iOS without project-owned Swift source.
  5. Walk scenarios: new Swift project without formatting config; existing
     formatter; Swift-only library; Kotlin-only Android app; cross-platform app
     without Swift; mixed app with project-owned Swift; unavailable formatter.
     Confirm no tool installation, reformatting, or config replacement occurs.
  6. Run `git diff --check`; check source citations and guide-selection consistency.
     Commit task files, then the plan update separately.

## Phase 2: Implementation and review evidence

- [ ] Task: Carry approved design decisions and platform evidence through implementation and review [needs classification]

  **Files:** Modify `.opencode/command/implement.md`,
  `.opencode/command/review.md`, `README.md`, and `skill/SKILL.md` only as needed
  for concise implement/review contract updates.
  **Consumes:** Optional track `design.md`, approved specification/plan,
  selected code guides, and project verification commands.
  **Produces:** Consistent execution and evidence requirements without changing
  track metadata statuses, adding new commands, or breaking legacy tracks.

  1. Make implementation read a track's design artifact when applicable and
     selected style guides before coding. Do not require legacy or non-UI tracks
     to have `design.md`; honor existing approved scope rather than inventing one.
  2. Add scoped review checks for web viewport/responsive behavior, keyboard
     access, and accessibility. For iOS/Android, use simulator/device evidence,
     text scaling, VoiceOver/TalkBack checks, and platform navigation/interaction.
     Static code inspection alone cannot prove screen-reader or runtime behavior.
  3. Include affected loading, empty, error, success, permission, and recovery
     states as applicable to the approved brief. Record evidence by platform;
     never treat a mobile web viewport as native verification.
  4. Run confirmed formatting checks without silently modifying code. Distinguish
     failed checks, unavailable tools, and checks outside approved scope.
  5. Extend the existing review report with design/platform evidence where
     applicable. Required acceptance criteria without evidence block closure
     unless explicitly revised with approval; maintain the existing final
     approval gate and correction loop.
   6. Update README usage with the platform split, optional web skill, consent-based
      installation and setup initialization handoff, restart and first-use fallback,
      derived `PRODUCT.md` authority,
      native guidance, Swift guide selection, and unchanged lifecycle.
  7. Walk scenarios: legacy track without design artifact; native browser-only
     preview; missing device; missing screen-reader verification; unavailable
     formatter; required criterion failed; explicitly approved criterion revision.
     Assert accurate **not verified** reporting and appropriate closure behavior.
  8. Run `git diff --check`; compare canonical doctrine with command instructions
     and wrappers. Update a compatibility wrapper only if it conflicts.
     Commit task files, then the plan update separately.

## Phase 3: End-to-end verification [manual-checkpoint]

- [ ] Task: Verify installed assets and full lifecycle scenario coverage [e2e-flow]

  **Files:** Create `conductor/scripts/test-installer.sh`;
  evidence goes in the existing phase git note and track review report.
  **Consumes:** Updated lifecycle docs, Swift asset, and unchanged `install.sh`.
  **Produces:** A repeatable isolated install smoke test and track-level evidence.

  1. After the documentation changes exist, add a POSIX shell regression test
     following existing test scripts' temporary-directory conventions. Resolve
     installer path before changing directory, use a fresh temporary HOME and
     working directory, and clean up only the directory this test created.
     Never run the installer against the user's real home.
  2. Invoke `bash <absolute-repository-path>/install.sh` from outside its root,
     with the temporary HOME. Assert installed canonical skill and four lifecycle
     commands match source; `swift.md` matches the source asset; workflow template
     retains its version marker. Run twice and assert repeat installation succeeds.
     Installer output must not imply Impeccable was installed.
  3. Run `sh conductor/scripts/test-installer.sh`,
     `sh conductor/scripts/test-open-pr.sh`,
     `sh conductor/scripts/test-archive-track.sh`, and `git diff --check`.
     Expected: all exit zero with explicit PASS output for each test script.
  4. During `/conductor/review`, record each scenario from Tasks 1–3 with inputs,
     expected result, observed instruction routing, and evidence. Distinguish
     document walkthroughs from actual host-agent executions; do not claim the
     former proves autonomous agent compliance.
  5. If host tools cannot execute a scenario, record that limitation and apply
     the approved acceptance/evidence policy rather than inventing results.
     No mobile or web application is created merely to exercise this tooling.
  6. Commit the test and plan update separately. Follow the manual phase
     checkpoint, then stop for the separately invoked `/conductor/review`.

## Planning readiness

- Specification approved before artifact creation.
- Optional setup initialization and first-use fallback approved as a specification
  amendment; this amendment updates planning artifacts only.
- Assisted installation, post-install discovery checks, and restart deferral
  reflect the subsequent agreed setup behavior; no installation or initialization
  is performed by this tooling track.
- Scope, artifact shapes, routing, fallback/error behavior, compatibility,
  acceptance criteria, and verification approach are defined.
- Runtime application data models and service API contracts are not applicable.
- No auto-decided open specification questions were recorded.
- Documentation task classification and implementation-plan approval remain pending.
