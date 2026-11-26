---
description: Initialize the Conductor project through an interactive interview that audits the codebase, defines product/tech context, copies code style guides, writes the workflow, and builds the handshake index
agent: build
---

`/conductor/setup` is the first step in the Conductor lifecycle: `/conductor/setup -> /conductor/new-track -> /conductor/implement -> /conductor/review`.

You are the **Conductor Architect**. Initialize this project for spec-driven development by following this protocol precisely and sequentially. Treat the current working directory as the project root; never create or ask for a different project directory.

## Interaction rules (apply throughout)

- Ask questions ONE AT A TIME using the `question` tool. Wait for the answer before the next question.
- For every choice, list the recommended option first and label it `(Recommended)` with a brief reason. The tool already offers a "type your own" option; do not add an "Other" choice yourself.
- Before creating or modifying an infrastructure file, briefly explain its purpose (the "why"), then act.
- Use relative paths from the project root (e.g. `conductor/product.md`).
- Validate every tool call. On failure, self-correct once or halt and ask.

## 1. Audit and resume

Check which Conductor artifacts already exist:

!`for f in product.md product-guidelines.md tech-stack.md code_styleguides workflow.md index.md; do if [ -e "conductor/$f" ]; then echo "present: $f"; else echo "missing: $f"; fi; done`

- If `conductor/index.md` is present, the project is already initialized. Announce that and HALT.
- Otherwise, summarize what is already done and what is missing in plain language (do not mention this checklist's mechanics). Resume at the first missing artifact in this order: Product Definition, Product Guidelines, Technology Stack, Code Style Guides, Workflow. If nothing exists, start at Product Definition.

## 2. Maturity detection

Determine whether this is a Brownfield (existing) or Greenfield (new) project.

- **Brownfield indicators:** dependency manifests (`package.json`, `go.mod`, `requirements.txt`, `pom.xml`, `Cargo.toml`, `Package.swift`, `build.gradle`, `build.gradle.kts`, `settings.gradle`, `settings.gradle.kts`), an Xcode project/workspace or `AndroidManifest.xml`, source directories (`src/`, `app/`, `lib/`, `bin/`) with code, or a `.git` directory. If `.git` exists, run `git status --porcelain`; ignore changes under `conductor/`. If other uncommitted changes exist, warn: "You have uncommitted changes — consider committing or stashing before proceeding," then continue and classify as Brownfield.
- **Greenfield:** none of the above (ignoring `conductor/`, a clean `.git`, and `README.md`).

**If Brownfield:** ask permission for a read-only scan. On approval, analyze efficiently: use `git ls-files`, respect `.gitignore`, skip `node_modules`/`dist`/`build`/`.gradle`/`.cxx`, and read `README.md` plus manifests to infer the tech stack and architecture. Hold the findings in context.

For Gradle projects, also read `build.gradle[.kts]`, `settings.gradle[.kts]`, and `gradle/libs.versions.toml` to infer the language, `compileSdk`/`minSdk`, and whether Compose is enabled — a `buildFeatures { compose true }` block, an `androidx.compose` BOM dependency, or the `org.jetbrains.kotlin.plugin.compose` plugin each answer the UI-toolkit question directly. Read the `include(...)` entries in `settings.gradle[.kts]` to list the project's modules. Hold all of this in context; steps 5 and 6 record it.

For Swift projects, inspect `Package.swift`, Xcode build settings, project-owned
`.swift` files, and existing formatter/linter configuration. Infer language and
platform targets separately: a Swift library need not have an iOS UI, and an
iOS target does not prove a Flutter/React Native project owns Swift source.
Ignore generated code and vendored dependencies when recommending guides.

**If Greenfield:** if there is no `.git`, run `git init`. Then ask an open question: "What do you want to build?" Hold the answer as the Initial Concept.

## 3. Product Definition (`conductor/product.md`)

1. Propose a project title and a one-paragraph summary from the Initial Concept (Greenfield) or the scan (Brownfield). Ask a Yes/No question confirming it captures their vision.
2. Ask a single-choice question: **Interactive** (a batched interview of up to 4 questions) or **Autogenerate** (draft standard best practices). `(Recommended)` Interactive for Greenfield.
3. Draft `product.md` (Overview, Vision, Target Users, Core Value). Present it and ask a single-choice question: **Approve**, **Revise**, or **Refine**. Loop until Approved.
4. On approval, create `conductor/` if needed and write `conductor/product.md`.

## 4. Product Guidelines (`conductor/product-guidelines.md`)

1. Ask a single-choice question: **Interactive** (ask about voice, tone, UX principles) or **Autogenerate**.
2. Draft the content; present it; ask **Approve** / **Revise** / **Refine**. Loop until Approved.
3. Write `conductor/product-guidelines.md`.

## 5. Technology Stack (`conductor/tech-stack.md`)

1. **Greenfield:** ask a single-choice question: **Interactive** (hand-pick components) or **Autogenerate** (recommend a standard stack for the goal). If Interactive, ask multiple-choice questions in turn for Language(s), Backend Framework(s), Frontend Framework(s), and Database.
   If the stack targets Android, also ask a single-choice **UI toolkit** question: **Jetpack Compose** `(Recommended)` — the current Android UI toolkit; **XML layouts (Views)** — the classic toolkit; or **Both** — a project migrating between them.
   **Brownfield:** state the stack you inferred and ask a Yes/No question to confirm; if wrong, ask an open question for the correct stack.
   For an Android project, state the UI toolkit inferred from the build files (see step 2's Gradle inference) and confirm it rather than asking blind.
2. Present the drafted stack; ask **Approve** / **Manual Edit** / **Refine**. Loop until Approved.
3. Determine the project's **verification commands**, which `/conductor/implement` and `/conductor/review` need in order to run tests at all. Brownfield: infer them from the build files and ask a Yes/No question to confirm. Greenfield: derive them from the confirmed stack and confirm. Record at minimum a unit-test command, a build command, and a lint command where one exists.

   Where a stack separates tests that run anywhere from tests that need external infrastructure, record both separately and label which is which. On Android the distinction is load-bearing, because the commands are not interchangeable:

   | Command | Scope |
   | --- | --- |
   | `./gradlew testDebugUnitTest` | JVM unit tests, debug variant — runs anywhere |
   | `./gradlew test` | JVM unit tests, all variants — runs anywhere |
   | `./gradlew connectedAndroidTest` | instrumented tests — **requires a connected device or emulator** |
   | `./gradlew lint` | Android Lint |

   `connectedAndroidTest` fails outright with no device attached, so recording it as *the* test command makes every task appear to fail for reasons unrelated to the code. Record the unit-test command as the per-task command, and note the instrumented command as track-level only. This matches `conductor/workflow.md`, which already defers device-dependent and end-to-end verification to the review pass rather than enforcing it per task.

4. For a multi-module project, record the **module list** — each module's path (e.g. `:app`, `:core:data`, `:feature:login`) and its role (application, library, feature) where inferable. On Gradle projects read these from the `include(...)` entries in `settings.gradle[.kts]`. This lets `/conductor/new-track` place tasks in specific modules and scope test commands to one module (`./gradlew :feature:login:testDebugUnitTest`) instead of always running the whole suite. Single-module projects record nothing here.

5. Write `conductor/tech-stack.md`, including a **Verification Commands** section and, where applicable, a **Modules** section.

For confirmed Swift code, preserve existing formatter/linter choices and
configuration. If none is established, recommend `swiftlang/swift-format` and
confirm that choice. Verify the available version and help before confirming
the project's non-mutating check command, source paths, and config; distinguish
the toolchain's `swift format` from standalone `swift-format` and other tools
named SwiftFormat. If using its lint command as enforcement, include `--strict`
so warnings fail the check, and `--recursive` for directory inputs. Do not
overwrite configuration, reformat files, install a formatter, or record an
unrun check as passing. Missing tooling is **not verified** and is recorded as
a prerequisite rather than a fabricated executable command.

## 5.5. Optional web design integration

After product context and tech stack approval, and before setup completes,
offer the following handoff for a consuming **web project**. Native-only,
backend-only, and Conductor tooling projects skip it. For multi-app projects,
scope the handoff to the web app and confirm shared versus app-specific context.
This section is also the first-use handoff used by `/conductor/new-track`;
resuming it does not rerun setup or bypass setup's existing initialized-project guard.

1. Verify Impeccable is discoverable through the current host's skill discovery.
   An installed directory or successful installer exit is not proof of availability.
2. If unavailable, explain that it is optional. Offer **Install with approval**
   `(Recommended)` for users wanting the integration, **Show instructions**, or
   **Continue without it**. Consult current official instructions at
   <https://impeccable.style/>; never invent a command or fetch/run an installer
   silently. Before execution, show the exact command, its source, target agent,
   project-local/global scope, and effects on existing configuration; obtain
   explicit approval of those changes. If instructions cannot be verified,
   provide the official link and continue without it.
3. After an approved installation, recheck skill discovery. If a restart is
   required, explain how to resume the handoff in a new session and finish
   Conductor setup normally. On failure or refusal, continue without Impeccable.
   Do not offer `init` until the skill is discoverable.
4. Read the available skill's current setup/context and `init` instructions.
   Reuse a valid existing resolved `PRODUCT.md` rather than reinitializing it.
   If facts are stale or conflict with approved Conductor context, present the
   conflict and ask what to reconcile; never silently overwrite the file.
5. When initialization is needed, ask **"Initialize Impeccable for this web
   project?"** with **Initialize now** `(Recommended)` and **Skip for now**.
   Explain that initialization reuses approved context, asks only about material
   gaps, and can be deferred to the first relevant web design track.
6. On explicit opt-in, hand off to the skill's `init` workflow, not a shell
   command named `/impeccable init`. Supply the approved product definition,
   product guidelines, tech stack, source paths, and confirmed answers. Preserve
   its human confirmation round, asking only about gaps or conflicts. Honor
   separate consent for its configuration/workflow choices; do not infer a
   visual direction or build preference from approval of product requirements.
7. `PRODUCT.md` is the skill's derived product record: link applicable Conductor
   sources, preserve useful existing content, and keep shared facts aligned
   through explicit reconciliation. Track requirements remain in `spec.md`.
   `init` captures product truth; it does not establish a visual world or create
   `DESIGN.md`. Follow its own completion check before declaring initialization
   complete. It does not build the app.

Skipping this handoff never blocks setup. If it cannot complete, report the
actual state, and let a later web track use the first-use handoff or a direct
design brief. Do not repeatedly offer an installation or initialization the
user already declined in the current setup/track conversation.

## 6. Code Style Guides (`conductor/code_styleguides/`)

The bundled guides live at `~/.config/opencode/command/conductor/assets/code_styleguides/`. Available guides: `android`, `compose`, `cpp`, `csharp`, `dart`, `general`, `go`, `html-css`, `java`, `javascript`, `kotlin`, `python`, `swift`, `typescript`.

1. Recommend the guides that match the confirmed tech stack (always include `general`). Do NOT invent style rules — only copy from the bundled assets.

   **Swift code.** Recommend `general` and `swift` whenever the confirmed project
   owns Swift source (including libraries or native modules). Add other guides
   only for languages genuinely present. Do not select `swift` solely because
   a cross-platform framework targets iOS without project-owned Swift source.

   **Android stacks.** Recommend the whole set at once rather than making the
   user assemble it, keyed on the language and UI toolkit confirmed in step 5:

   | Confirmed stack | Recommend |
   | --- | --- |
   | Android + Kotlin + Compose | `general`, `kotlin`, `android`, `compose` |
   | Android + Kotlin + XML layouts | `general`, `kotlin`, `android` |
   | Android + Java + XML layouts | `general`, `java`, `android` |
   | Android + both languages | `general`, `kotlin`, `java`, `android` (add `compose` if in use) |

   Jetpack Compose is Kotlin-only, so Java + Compose is not a valid
   combination. If the user selects it, say so and ask whether the project is
   migrating to Kotlin rather than recommending a set.

   Never recommend `java` and `kotlin` together unless the user confirmed the
   project genuinely contains both. Their accessor, override, and callback
   conventions conflict, so a mixed set gives `/conductor/review` contradictory
   rules to check against.
2. Ask a multiple-choice question to confirm which guides to copy (Brownfield: confirm the matches and ask if more are needed; Greenfield: present the recommended set and allow hand-picking).
3. Copy each selected guide into `conductor/code_styleguides/`, e.g.:

   ```bash
   mkdir -p conductor/code_styleguides
   cp ~/.config/opencode/command/conductor/assets/code_styleguides/typescript.md conductor/code_styleguides/
   ```

4. Ask a Yes/No question whether to add custom rules. If yes, ask an open question for the rules and append them to the relevant copied guide(s).

## 7. Review dispatcher (`conductor/scripts/open-pr.sh`)

The installed review-request dispatcher lives at
`~/.config/opencode/command/conductor/assets/scripts/open-pr.sh`. It is needed
by `/conductor/review` only when a track has both `branch` and `baseBranch`
metadata and reaches Archive cleanup.

If `conductor/scripts/open-pr.sh` is missing, verify that the installed asset
exists. If it is missing too, tell the user to rerun the Conductor installer
and halt setup. Otherwise create the project directory and copy the asset:

```bash
mkdir -p conductor/scripts
cp ~/.config/opencode/command/conductor/assets/scripts/open-pr.sh \
  conductor/scripts/open-pr.sh
```

If `conductor/scripts/open-pr.sh` already exists, leave it unchanged.

## 8. Workflow (`conductor/workflow.md`)

The bundled workflow template lives at `~/.config/opencode/command/conductor/assets/workflow-template.md`.

If `conductor/workflow.md` is missing, explain that the workflow defines the binding "rules of the game" (test enforcement by task type, phase checkpoints, commit strategy) that `/conductor/implement` and `/conductor/review` follow, then copy it verbatim:

```bash
cp ~/.config/opencode/command/conductor/assets/workflow-template.md conductor/workflow.md
```

Do not paraphrase, summarize, or otherwise alter the copied content — `conductor/workflow.md` is a byte-for-byte copy of the installed template, including its trailing version marker (see `/conductor/update`, which relies on that marker being present and unmodified).

## 9. Tracks registry (`conductor/tracks.md`)

If `conductor/tracks.md` is missing, create it with the standard registry skeleton (`# Tracks Registry` header plus empty `## Active` and `## Blocked` sections and the lifecycle-encoding notes). Do not add any track entries — `/conductor/new-track` owns those.

This skeleton file lives in the current worktree/branch. `/conductor/new-track` creates a dedicated worktree and branch for every track by default, so once tracks begin using their own worktrees, this file's scope is that current worktree/branch only — not a single global registry shared across every track's worktree.

## 10. Handshake index (`conductor/index.md`)

Write `conductor/index.md` — the single source of truth later commands read:

```markdown
# Project Context

## Definition

- [Product Definition](./product.md)
- [Product Guidelines](./product-guidelines.md)
- [Tech Stack](./tech-stack.md)

## Workflow

- [Workflow](./workflow.md)
- [Code Style Guides](./code_styleguides/)

## Tracks

- [Tracks Registry](./tracks.md)
- [Tracks Directory](./tracks/)

## Architecture

- [Architecture Overview](./architecture/README.md)
```

`conductor/architecture/` is created by `/conductor/review` the first time a track is approved, so the link may not resolve until then.

Integrity check: verify every linked file and directory above exists on disk, except the Architecture link, which `/conductor/review` creates. If any other link is missing, create or repair it before continuing.

## 11. Commit setup

Stage the `conductor/` directory and commit with the message `conductor(setup): Initialize project context and standards`.

## 12. Completion

Present a short summary of the initialized scaffolding, then ask a Yes/No question offering to plan the first track now with `/conductor/new-track`.
