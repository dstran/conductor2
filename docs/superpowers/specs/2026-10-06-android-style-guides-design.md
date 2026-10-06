# Android Development Support in `/conductor/setup`

**Goal:** Make `/conductor/setup` able to initialize an Android project — Java or
Kotlin, classic XML layouts or Jetpack Compose — by adding four bundled code
style guides, an Android recommendation rule, Gradle brownfield detection, and
recorded verification commands.

**Status:** Design approved; ready for implementation planning.

## Problem

This repository ships nine code style guides at
`conductor/assets/code_styleguides/`: `cpp`, `csharp`, `dart`, `general`, `go`,
`html-css`, `javascript`, `python`, `typescript`. None covers Java, Kotlin,
Android XML layouts, or Jetpack Compose.

Four concrete gaps block Android setup:

1. **No Android style guides.** A user confirming an Android stack in step 6 of
   `.opencode/command/setup.md` has nothing to copy but `general.md`. Setup is
   forbidden from inventing rules (`setup.md:62`), so the project ends up with
   29 lines of generic principles.
2. **Gradle projects are invisible to maturity detection.** `setup.md:31` lists
   brownfield indicators as `package.json`, `go.mod`, `requirements.txt`,
   `pom.xml`, `Cargo.toml`. An existing Android project with no `.git` directory
   and non-`app/` module names is classified Greenfield. Setup then asks "What
   do you want to build?" about a codebase that already exists and skips the
   read-only audit entirely.
3. **No test or build command is ever recorded.** `review.md:52` instructs
   running "the entire test suite for the project" and
   `workflow-template.md:53` requires a passing unit test before any
   `backend-logic` or `api-client` task is marked complete, but setup never
   writes down how to run tests. For npm projects an agent guesses `npm test`
   and is usually right; Android has no comparable default and the options are
   not interchangeable. This is the highest-impact gap in this spec: a wrong
   test command breaks every task in `implement` and every track in `review`.
4. **Module layout is never captured.** Android projects are commonly
   multi-module (`:app`, `:core:data`, `:feature:login`). Every task lands in a
   specific module and tests are typically run per-module
   (`./gradlew :feature:login:test`). `settings.gradle.kts` lists the modules
   explicitly, so this is cheap to record and is the single most useful fact for
   planning Android tracks.

The Conductor workflow itself is language-agnostic and needs no change.
`skill/SKILL.md` contains no language, build-system, or test-runner references,
and that is correct.

## Scope

In scope:

- Four new guide files: `kotlin.md`, `java.md`, `android.md`, `compose.md`
- `.opencode/command/setup.md`: available-guides list, Android bundle
  recommendation, Java/Kotlin co-selection guard, UI-toolkit question
- `.opencode/command/setup.md`: Gradle brownfield indicators, Gradle stack
  inference, Gradle scan exclusions
- `.opencode/command/setup.md`: record verification commands (test, build, lint)
  and module layout in `tech-stack.md`
- `conductor/assets/workflow-template.md`: two general task-type enforcement
  gaps that Android exposes, plus the missing version marker

Out of scope:

- Other language gaps (`swift`, `rust`, `ruby`)
- Gradle build-file generation, dependency management, AGP version handling
- Android-specific `new-track`, `implement`, or `review` logic. See
  "Why command logic stays platform-neutral" below — this exclusion is load
  bearing, and the two real taxonomy gaps Android exposes are closed in shared
  doctrine instead (Edit H).
- `skill/SKILL.md` doctrine changes
- `README.md` (does not enumerate guides)
- **Greenfield Android scaffolding.** Setup does not generate a Gradle wrapper,
  `settings.gradle.kts`, modules, or a manifest. `skill/SKILL.md:17` scopes
  setup to "Conductor project context and handshake artifacts," and pinning
  AGP/Kotlin/SDK versions inside a prompt would rot immediately. A greenfield
  Android project therefore still has no code after setup; the user is expected
  to create it (Android Studio or `gradle init`) or let the first track own
  scaffolding as an explicit phase. Documented here as a known limitation.
- **`.gitignore` generation on `git init`.** Greenfield setup (`setup.md:36`)
  runs `git init` without a `.gitignore`, so a later Android build produces
  `build/`, `.gradle/`, `.idea/`, and machine-specific `local.properties`. Real
  but not blocking, and not Android-specific enough to solve here.

## Architecture

No runtime code. Four new markdown assets plus edits to one command prompt.

```
conductor/assets/code_styleguides/
  kotlin.md    (new)  Android Kotlin style guide  - language only
  java.md      (new)  Google Java Style Guide     - language only
  android.md   (new)  platform: XML layouts, resources, manifest, lifecycle
  compose.md   (new)  Jetpack Compose + Compose API guidelines
.opencode/command/setup.md   (edit) guide list, bundle rule, UI-toolkit question
                             (edit) Gradle brownfield detection
```

`install.sh:40` copies `conductor/assets/code_styleguides/*.md` with a glob, so
installation requires no change. The `wc -l`-based count assertion of nine
guides appears only in the historical plan document
`docs/superpowers/plans/2026-07-28-setup-interview-parity.md:91`, not in any
live script, so adding files breaks nothing.

### Why four files, not one

A single `android.md` would be one selectable unit, which is simpler to pick.
It is rejected for two reasons.

**Relevance and cost.** `.opencode/command/review.md:42` reads everything in
`conductor/code_styleguides/` and checks changed files against it. A Kotlin +
Compose project would carry Java and XML rules it can never use.

**Rule conflicts.** Java and Kotlin prescribe genuinely opposite conventions:

| Java | Kotlin |
| --- | --- |
| `getFoo()` / `setFoo()` accessors | properties; never write `getFoo()` |
| `@Override` annotation on overrides | `override` is a required modifier |
| anonymous inner classes for callbacks | lambdas / SAM conversion |
| `private final` fields, constructor-injected | `val` in the primary constructor |

Whether a reviewer actually misapplies a Java rule to a `.kt` file is plausible
but unproven — `review.md:42` scopes the check to changed files, so it may well
scope rules by extension. The split rests primarily on relevance and token
cost, which are not speculative.

The Compose/XML split is the weaker of the two seams: those rule sets are
largely irrelevant to each other rather than contradictory. It is still made,
because an XML-only legacy project has no use for recomposition rules.

### Boundary rule

Each rule lives in exactly one file:

- `kotlin.md` and `java.md` never mention Android or Compose
- `android.md` never contains Kotlin-vs-Java syntax rules
- `compose.md` never contains XML or View-system rules

### Format contract

Each new guide follows the convention established by `typescript.md` and
`dart.md`:

- `# <Name> Style Guide` or `Summary` H1
- One-paragraph preamble naming the upstream authority
- Numbered `## N. Topic` sections
- Dash bullets, 4-space continuation indent, prose wrapped at 80 columns
  (existing guides run to 85 where a URL or long identifier cannot be broken;
  the same tolerance applies)
- Imperative rules, bold directive (`**Do not use ...**`)
- Closing `*Source:*` or `*Sources:*` link footer

Content is summarized from upstream authorities only. No invented rules.

| File | Authority |
| --- | --- |
| `kotlin.md` | developer.android.com Kotlin style guide; kotlinlang coding conventions |
| `java.md` | google.github.io/styleguide/javaguide.html |
| `android.md` | Android developer guides: resources, manifest, lifecycle, architecture |
| `compose.md` | developer.android.com Compose documentation; Compose API guidelines |

### Line budgets

Existing guides run 29–297 lines (median ~75), totalling 981. Android has more
surface area than any single language here; written at `dart.md` scale the four
files would exceed the entire existing corpus, and an Android project would
load more style text than any other stack. Budgets are therefore binding:

| File | Budget |
| --- | --- |
| `kotlin.md` | <= 120 |
| `java.md` | <= 110 |
| `android.md` | <= 130 |
| `compose.md` | <= 110 |

Worst-case Android bundle: `general` 29 + `kotlin` 120 + `android` 130 +
`compose` 110 = 389 lines, comparable to a `cpp` + `dart` project today.

### Checkable rules before architectural guidance

Most Android guidance is architectural judgment ("don't leak `Context`", "hoist
state", "survive configuration changes") rather than mechanical style ("use
`const`, not `var`"). Architectural rules cannot be verified from a diff, so a
reviewer either stays silent or invents violations.

`android.md` and `compose.md` therefore lead with diff-verifiable rules:

- resource and ID naming conventions
- no hardcoded strings or dimensions in layouts
- `sp` for text sizes, `dp` for all other dimensions
- composable naming and `@Composable` return conventions
- modifier parameter position and ordering
- `remember` key correctness

Judgment-based guidance is confined to a final section explicitly labelled as
architectural guidance rather than mechanical rules. A rule that cannot be
assessed from a diff belongs in `tech-stack.md`, not a style guide.

## Changes to `setup.md`

### Edit A — UI toolkit question (step 5, `setup.md:53`)

The interactive stack branch asks Language(s), Backend Framework(s), Frontend
Framework(s), Database. "Frontend Framework" does not resolve XML versus
Compose, so the bundle rule would have nothing to key off.

Add a conditional question: if the confirmed stack targets Android, ask a
single-choice **UI toolkit** question — **Jetpack Compose** `(Recommended)`,
**XML layouts (Views)**, or **Both (migrating)** — and record the answer in
`tech-stack.md`. Non-Android projects see no change.

### Edit B — guide list and bundle rule (step 6, `setup.md:60`)

Extend the available list alphabetically:

```
android, compose, cpp, csharp, dart, general, go, html-css, java,
javascript, kotlin, python, typescript
```

Add the Android recommendation table so the user confirms one pre-assembled set
rather than hand-picking from thirteen:

| Confirmed stack | Recommend |
| --- | --- |
| Android + Kotlin + Compose | `general`, `kotlin`, `android`, `compose` |
| Android + Kotlin + XML | `general`, `kotlin`, `android` |
| Android + Java + XML | `general`, `java`, `android` |
| Android + both languages | `general`, `kotlin`, `java`, `android` (+ `compose` if in use) |

Java + Compose is not a valid combination; Compose is Kotlin-only. If the user
selects it, setup flags the contradiction and asks whether this is a Kotlin
migration rather than silently recommending a set.

Add the co-selection guard: never recommend `java` and `kotlin` together unless
the user confirmed the project genuinely contains both, because their accessor,
override, and callback conventions conflict.

This rides existing mechanisms. `setup.md:62` already instructs recommending
guides that match the confirmed stack, and `:63` already asks a multiple-choice
confirmation. Android simply becomes legible to that logic. The user retains
full override freedom; only the default changes.

### Edit C — brownfield indicators (step 2, `setup.md:31`)

Add to the indicator list: `build.gradle`, `build.gradle.kts`,
`settings.gradle`, `settings.gradle.kts`, and `AndroidManifest.xml`. The
manifest identifies the project as Android specifically rather than merely JVM.

This is a literal filename list, not an inference rule, so correctness is
reviewable by eye.

### Edit D — Gradle stack inference (step 2, `setup.md:34`)

The brownfield scan reads "`README.md` plus manifests." Make Gradle explicit:
read `build.gradle[.kts]`, `settings.gradle[.kts]`, and
`gradle/libs.versions.toml` to infer language, `compileSdk` / `minSdk`, and
whether Compose is enabled.

This matters because Edit A's UI-toolkit question should not be asked blind on
a brownfield project. A `buildFeatures { compose true }` block, an
`androidx.compose` BOM dependency, or the `org.jetbrains.kotlin.plugin.compose`
plugin answers it directly, so setup states what it found and asks for
confirmation, consistent with the brownfield pattern at `setup.md:54`.

### Edit E — scan exclusions (step 2, `setup.md:34`)

The scan skips `node_modules`, `dist`, and `build`. `build` already covers
Gradle output; add `.gradle`, `.cxx`, and `app/build`. These directories are
large and the scan is specified as efficient.

### Edit F — record verification commands (step 5, `tech-stack.md`)

Closes gap 3. After the stack is confirmed, setup records a **Verification
Commands** section in `conductor/tech-stack.md` holding the project's test,
build, and lint commands. Brownfield: infer from the build files and ask for
confirmation. Greenfield: derive from the chosen stack and confirm.

This is not Android-specific — every stack benefits — but Android is where the
absence actively breaks, because the options are not interchangeable:

| Command | Scope |
| --- | --- |
| `./gradlew test` | JVM unit tests, all variants |
| `./gradlew testDebugUnitTest` | JVM unit tests, debug variant only |
| `./gradlew connectedAndroidTest` | instrumented tests; **requires a device or emulator** |
| `./gradlew check` | tests plus lint |

`connectedAndroidTest` fails with no device attached, so an agent that guesses
it reports failures that are not code defects. The recorded section must
therefore distinguish the **unit test command** (runnable in any environment,
used per-task) from the **instrumented test command** (needs a device, run at
track level), and note that instrumented tests require a device.

That distinction maps onto the existing workflow template without changing it.
Compose UI tests and Espresso tests are instrumented, which is exactly
`workflow-template.md`'s `e2e-flow` category — "validated once, at the end of
the track during `/conductor/review`" (`workflow-template.md:55`), never
test-first (`:22`). The template already encodes the right behavior; it just
cannot know which Android command belongs to which category unless setup writes
it down.

`review.md:52` ("run the entire test suite") and `workflow-template.md:53`
(passing unit test per task) then have a concrete command to use instead of a
guess. Neither file changes.

### Edit G — record module layout (step 5, `tech-stack.md`)

Closes gap 4. For multi-module projects, setup records the module list in
`tech-stack.md`, read from `settings.gradle[.kts]` `include(...)` entries on
brownfield. Capture each module's Gradle path (`:core:data`) and its role where
inferable (app, library, feature).

This gives `/conductor/new-track` the vocabulary to place tasks in specific
modules and to scope per-module test commands (`./gradlew :feature:login:test`)
rather than always running the whole suite. Non-modular projects record nothing
and are unaffected.

## Why command logic stays platform-neutral

`new-track`, `implement`, and `review` get no Android branches. Two reasons.

**Doctrine.** `skill/SKILL.md` contains no language, build-system, or
test-runner reference, and `skill/SKILL.md:72` states that command docs "do not
define a competing methodology," with any local difference kept "explicit and
narrow." Branching on platform in these commands would invite iOS, Rails, and
Unity branches by the same precedent.

**Every gap found is closable by recording a fact or fixing shared doctrine,**
not by branching. Edits F and G record facts. Edit H fixes a shared table. No
Android conditional is required anywhere.

### Where platform guidance can actually be read

This constrains placement more tightly than it first appears:

| File | Read by |
| --- | --- |
| `conductor/workflow.md` | `new-track.md:97`, `implement.md:7`, `review.md:6` |
| `conductor/index.md` | `new-track.md:8`, `implement.md:5`, `review.md:7` |
| `conductor/tech-stack.md` | **not read by `new-track.md`** (`grep -c` = 0) |
| `conductor/code_styleguides/` | `review.md:42`, for style checking only |

`new-track` is the component that assigns task-type tags. It never reads
`tech-stack.md` and never reads the style guides. Therefore a task-type mapping
placed in either file would be invisible to the tagger. Only `workflow.md`
reaches all three commands, which is why Edit H goes there.

### Edit H — close two general enforcement gaps (`workflow-template.md`)

Android exposes two holes in the enforcement table (`workflow-template.md:14-22`).
Neither is Android-specific; Android merely makes them common.

**Pure presentation-layer logic is demoted to test-after.** An Android ViewModel
tagged `frontend-ui` gets "test-after, test-first optional"
(`workflow-template.md:20`), yet it is pure JVM code with a knowable contract and
no device requirement — precisely the table's own stated rationale for strict
test-first. The same shape appears as React hooks, Vue composables, WPF
ViewModels, and Redux reducers. Amend the table so presentation-layer logic that
is pure and device-free is enforced test-first, leaving `frontend-ui` for
genuine view/styling work.

**Data-layer components needing external infrastructure cannot satisfy per-task
enforcement.** A Room DAO tagged `backend-logic` must have "at least one passing
unit test before the task is marked complete" (`workflow-template.md:53`), but
its canonical test is instrumented and needs a device. The same shape appears as
Postgres integration tests and Testcontainers suites. Amend the table so such
tasks enforce test-first on their unit-testable portion per-task, with
infrastructure-dependent tests deferred to track level — consistent with how
`e2e-flow` is already handled at `workflow-template.md:55`.

The existing `[needs classification]` hatch (`:24`) means neither gap is
breaking today. It is nonetheless worth fixing, because it fires on two of the
most common Android task types, so the user re-answers the same two questions
every track.

Framing matters: this is a general taxonomy fix motivated by Android, not an
Android feature. Written as a platform-neutral rule, it keeps the exclusion
above intact.

### Edit I — add the missing version marker (`workflow-template.md`)

Pre-existing bug, unrelated to Android, and a prerequisite for Edit H.

`setup.md:83` states the copied workflow includes "its trailing version marker,"
and `update.md:29` expects `<!-- conductor-workflow-version: <sha> -->` as the
last line. **The template has no such line** (`grep -c` = 0), and neither does
`conductor/workflow.md`. Per `update.md:30-37`, a missing template marker makes
the SHA `unknown` and a missing target marker "always counts as stale," so
`/conductor/update` reports stale unconditionally and its diff gate is
meaningless.

This must be fixed before Edit H, or the taxonomy change cannot be detected as
an update by the mechanism designed to propagate it.

Consequence to accept: once the template carries a marker and its content
changes, existing projects correctly report stale until they run
`/conductor/update`. That is the designed mechanism working as intended.

## Verification

| ID | Check |
| --- | --- |
| V1 | Run the real `install.sh` into a sandbox prefix; assert 13 guides land and all four new filenames are present |
| V2 | Each new file: H1 present, numbered sections, `*Source:*` footer, and no prose line exceeding 85 columns (matching the existing guides, which reach 85 where a URL or identifier cannot be broken) |
| V3 | Each new file within its line budget |
| V4 | Boundary grep: no Android/Compose terms in `kotlin.md` or `java.md`; no language-syntax rules in `android.md`; no XML/View rules in `compose.md` |
| V5 | The 13 names in `setup.md` match `ls conductor/assets/code_styleguides/` exactly |
| V6 | Edit C reviewed by eye as a literal filename list |
| V7 | A sandbox Gradle project exercising Edits F/G: confirm the recorded `tech-stack.md` separates unit from instrumented test commands and lists modules from `settings.gradle.kts` |
| V8 | `workflow-template.md` last line matches `<!-- conductor-workflow-version: <sha> -->`; `/conductor/update` reports up-to-date for a freshly set-up project instead of unconditionally stale |
| V9 | Edit H's amended enforcement table contains no Android, Gradle, or platform-specific terms |

There is no runtime code, so there are no unit tests. Prompt edits (A–I) cannot
be executed in isolation; V6 compensates by keeping the highest-risk edit
mechanical.

## Risks accepted

| Risk | Status |
| --- | --- |
| Mixed Java + Kotlin guides cause review false positives | Plausible, unproven. The split rests on relevance and token cost. |
| Prompt edits are not unit-testable | Accepted. Mitigated by keeping Edit C mechanical. |
| `compose.md` content ages fastest | Restricted to stable fundamentals; nothing version-pinned or experimental. |
| Upstream style guides drift | Pre-existing for all nine current guides. `*Source:*` footers enable recheck. |
| Line budgets force omitting real rules | Intended. These files are summaries, not specifications. |
| Bundle table drifts from the guide list | Four rows, colocated with the list they reference. |
| Edit F is a general Conductor improvement inside an Android spec | Accepted deliberately. It is a precondition for Android `implement`/`review` working at all, and scoping it Android-only would be worse. |
| Greenfield Android still has no code after setup | Known limitation, documented in Scope. Mitigated by setup stating it plainly and pointing at Android Studio, `gradle init`, or a scaffolding first phase. |
| Recorded commands go stale when build config changes | Same class as the style-guide drift risk. `/conductor/review` surfaces failures, and `tech-stack.md` is user-editable. |
| Edit H changes shared doctrine every project copies byte-for-byte | Accepted. Edit I makes the change detectable by `/conductor/update`, which is the mechanism designed for exactly this. Existing projects report stale until updated. |
| Edit H could be read as doctrine creep under an Android spec | Mitigated by V9: the amended table must contain no platform-specific terms. It is a general fix with an Android motivating example. |
| Edit I changes `/conductor/update` behavior for all existing projects | They currently always report stale, so the change strictly improves the signal. |
