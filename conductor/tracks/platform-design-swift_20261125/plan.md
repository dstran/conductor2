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
- Do not create new doctrine mirrors, global product files, or design tools.

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
  requirements document or duplicate discovery interview (Task 1 scenarios).
- Existing SwiftFormat/SwiftLint/formatter configuration must not be overwritten
  or confused with `swiftlang/swift-format` (Task 2 scenarios).
- Unavailable devices, accessibility tools, or formatter executables must not
  produce a pass or silently waive a required acceptance criterion (Task 3 scenarios).

## Phase 1: Design planning and Swift standards

- [ ] Task: Integrate platform-aware design planning into canonical doctrine and new-track [needs classification]

  **Files:** Modify `skill/SKILL.md`, `.opencode/command/new-track.md`.
  **Consumes:** Existing brainstorming, specification approval (Gate A), and
  plan approval sequence.
  **Produces:** A design decision checkpoint before Gate A; track-local
  `design.md` persisted only when applicable after approval, alongside the
  existing spec/plan/metadata artifacts.

  1. Read both files and the approved spec. Add a concise canonical contract
     for material UI design decisions; put operational detail in `new-track`.
  2. Route web to available Impeccable `shape` or a direct equivalent brief;
     route iOS/Android to their current official guidance. Detect availability
     through the host's skill discovery, not a hard-coded home directory.
     Never install a missing skill. Native use requires an explicit request.
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
  6. Walk scenarios: web skill present; absent; approved external design;
     iOS-only; Android-only; shared mobile framework targeting both platforms;
     backend-only; label correction using an existing component.
     Assert correct routing, no duplicate interview, and no coding before approval.
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
  6. Update README usage with the platform split, optional web skill, native
     guidance, Swift guide selection, and unchanged lifecycle.
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
- Scope, artifact shapes, routing, fallback/error behavior, compatibility,
  acceptance criteria, and verification approach are defined.
- Runtime application data models and service API contracts are not applicable.
- No auto-decided open specification questions were recorded.
- Documentation task classification and implementation-plan approval remain pending.
