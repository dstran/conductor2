# Android Development Support in `/conductor/setup`

**Goal:** Make `/conductor/setup` able to initialize an Android project — Java or
Kotlin, classic XML layouts or Jetpack Compose — by adding four bundled code
style guides, an Android recommendation rule, and Gradle brownfield detection.

**Status:** Design approved; ready for implementation planning.

## Problem

This repository ships nine code style guides at
`conductor/assets/code_styleguides/`: `cpp`, `csharp`, `dart`, `general`, `go`,
`html-css`, `javascript`, `python`, `typescript`. None covers Java, Kotlin,
Android XML layouts, or Jetpack Compose.

Two concrete gaps block Android setup:

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

Out of scope:

- Other language gaps (`swift`, `rust`, `ruby`)
- Gradle build-file generation, dependency management, AGP version handling
- Android-specific `new-track`, `implement`, or `review` logic
- `skill/SKILL.md` doctrine changes
- `README.md` (does not enumerate guides)

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

## Verification

| ID | Check |
| --- | --- |
| V1 | Run the real `install.sh` into a sandbox prefix; assert 13 guides land and all four new filenames are present |
| V2 | Each new file: H1 present, numbered sections, `*Source:*` footer, and no prose line exceeding 85 columns (matching the existing guides, which reach 85 where a URL or identifier cannot be broken) |
| V3 | Each new file within its line budget |
| V4 | Boundary grep: no Android/Compose terms in `kotlin.md` or `java.md`; no language-syntax rules in `android.md`; no XML/View rules in `compose.md` |
| V5 | The 13 names in `setup.md` match `ls conductor/assets/code_styleguides/` exactly |
| V6 | Edit C reviewed by eye as a literal filename list |

There is no runtime code, so there are no unit tests. Prompt edits (A–E) cannot
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
