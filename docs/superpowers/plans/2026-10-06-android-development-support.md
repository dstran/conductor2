# Android Development Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `/conductor/setup` able to initialize an Android project in either language (Java/Kotlin) and either UI toolkit (XML layouts/Jetpack Compose).

**Architecture:** This repository contains no runtime code. The deliverables are four new markdown style-guide assets, prompt edits to one command doc (`.opencode/command/setup.md`), and two enforcement-table rows in the shared workflow template. `install.sh` already globs `code_styleguides/*.md`, so installation needs no change.

**Tech Stack:** Markdown documents, Bash (`install.sh`), `git`. No build system, no test framework.

**Spec:** `docs/superpowers/specs/2026-10-06-android-style-guides-design.md`

## Global Constraints

- Style-guide format, copied from existing guides: `#` H1 title, one-paragraph preamble naming the upstream authority, numbered `## N. Topic` sections, dash bullets with 4-space continuation indent, bold directives (`**Do not use ...**`), closing `*Source:*` or `*Sources:*` footer.
- Prose wraps at 80 columns; **85 is the hard ceiling** (existing guides reach 85 where a URL or identifier cannot be broken). Markdown table rows are exempt.
- **No invented rules.** Every rule must be traceable to the upstream authority named in that file's preamble. `setup.md:62` forbids inventing style rules.
- Line budgets, enforced: `kotlin.md` ≤ 120, `java.md` ≤ 110, `android.md` ≤ 130, `compose.md` ≤ 110.
- Boundary rule, one rule one file: `kotlin.md` and `java.md` never mention Android or Compose; `android.md` contains no Kotlin-vs-Java syntax rules; `compose.md` contains no XML or View-system rules.
- `android.md` and `compose.md` lead with diff-verifiable rules; judgment-based guidance goes in a final section explicitly labelled as architectural guidance.
- **Do not** add a `conductor-workflow-version` marker to `conductor/assets/workflow-template.md`. `install.sh:42` generates it at install time; committing one produces duplicate marker lines.
- **Do not** add Android, Gradle, or any platform-specific term to `conductor/assets/workflow-template.md`. Its edits must be platform-neutral.
- **Do not** add Android branches to `new-track.md`, `implement.md`, or `review.md`.
- Commit after each task. Conventional commit messages.

## File Structure

| File | Responsibility | Tasks |
| --- | --- | --- |
| `conductor/assets/code_styleguides/kotlin.md` | Kotlin language rules only | 1 |
| `conductor/assets/code_styleguides/java.md` | Java language rules only | 2 |
| `conductor/assets/code_styleguides/android.md` | Platform: resources, XML layouts, manifest, lifecycle | 3 |
| `conductor/assets/code_styleguides/compose.md` | Jetpack Compose rules | 4 |
| `.opencode/command/setup.md` | Guide list + Android bundle rule (Edit B) | 5 |
| `.opencode/command/setup.md` | Gradle brownfield detection (Edits C, D, E) | 6 |
| `.opencode/command/setup.md` | UI-toolkit question + verification commands + module layout (Edits A, F, G) | 7 |
| `conductor/assets/workflow-template.md` | Two general enforcement-table gaps (Edit H) | 8 |

Tasks 1–4 are independent of each other. Tasks 5–7 all modify `setup.md` and must run in order. Task 8 is independent. Task 9 is final verification.

**Verification note:** There is no test framework. "Tests" in this plan are shell assertions run against the files. Each task's verification step must actually be run and its output observed — not assumed.

---

### Task 1: Kotlin style guide

**Files:**
- Create: `conductor/assets/code_styleguides/kotlin.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the filename `kotlin.md`, referenced by Task 5's guide list and Task 5's bundle table.

- [ ] **Step 1: Write the verification script first**

Create `/tmp/check-guide.sh` (scratch, not committed):

```bash
#!/bin/bash
# Usage: check-guide.sh <file> <max_lines>
f="$1"; max="$2"
fail=0
[ -f "$f" ] || { echo "FAIL: $f does not exist"; exit 1; }
head -1 "$f" | grep -q '^# ' || { echo "FAIL: no H1 on line 1"; fail=1; }
grep -q '^## 1\. ' "$f" || { echo "FAIL: no numbered section '## 1. '"; fail=1; }
grep -qE '^\*Sources?:' "$f" || { echo "FAIL: no *Source:* footer"; fail=1; }
n=$(wc -l < "$f" | tr -d ' ')
[ "$n" -le "$max" ] || { echo "FAIL: $n lines exceeds budget $max"; fail=1; }
long=$(awk 'length>85 && $0 !~ /^\|/ {print NR": "length}' "$f")
[ -z "$long" ] || { echo "FAIL: prose lines over 85 cols:"; echo "$long"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: $f ($n lines, budget $max)"
exit $fail
```

```bash
chmod +x /tmp/check-guide.sh
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `/tmp/check-guide.sh conductor/assets/code_styleguides/kotlin.md 120`
Expected: `FAIL: conductor/assets/code_styleguides/kotlin.md does not exist`

- [ ] **Step 3: Write `kotlin.md`**

Summarize from the Android Kotlin style guide (developer.android.com/kotlin/style-guide) and kotlinlang coding conventions (kotlinlang.org/docs/coding-conventions.html). Language rules only — no Android, Compose, Activity, or Gradle references.

Required structure (≤ 120 lines):

```markdown
# Kotlin Style Guide Summary

This document summarizes key rules from the Android Kotlin style guide and the
official Kotlin coding conventions.

## 1. Naming

-   **`UpperCamelCase`:** For classes, objects, interfaces, and type aliases.
-   **`lowerCamelCase`:** For functions, properties, parameters, and local
    variables.
-   **`CONSTANT_CASE`:** For `const val` properties and top-level or `object`
    `val` properties holding deeply immutable data.
-   **Backing properties:** Prefix with a single underscore (`_items`) only
    when a private backing property mirrors a public one.
-   **Test method names:** Backtick-quoted names with spaces are permitted in
    test code.
-   **Acronyms:** Treat as words — `IoStream`, not `IOStream`.

## 2. Language Features

-   **`val` over `var`:** Declare properties and locals `val` unless they must
    be reassigned.
-   **Type inference:** Omit the type when the initializer makes it obvious.
    Declare types explicitly on public API signatures.
-   **Expression bodies:** Use `=` for single-expression functions.
-   **Semicolons:** **Do not use semicolons.**
-   **Wildcard imports:** **Do not use wildcard imports.**
-   **`when` over `if` chains:** Prefer `when` for three or more branches.
-   **String templates:** Prefer `"$name"` over concatenation. Omit braces
    when not required.
-   **Trailing commas:** Permitted and encouraged in multi-line argument and
    parameter lists.
-   **`companion object`:** Place at the end of the class body.

## 3. Null Safety

-   **Avoid `!!`.** The not-null assertion operator defeats null safety; use
    `?.`, `?:`, `requireNotNull`, or `checkNotNull` with a message instead.
-   **Prefer non-nullable types.** Make a type nullable only when absence is
    meaningful.
-   **`lateinit`:** Use only when a non-null property genuinely cannot be
    initialized at construction, and never for types with a sensible default.
-   **Scope functions:** Use `?.let { }` for null-conditional blocks rather
    than nested `if (x != null)` checks.

## 4. Functions and Classes

-   **Default arguments over overloads:** Prefer default parameter values to
    multiple overloads.
-   **Named arguments:** Use for boolean literals and for calls with several
    same-typed parameters.
-   **Data classes:** Use for value holders; they supply `equals`, `hashCode`,
    `toString`, and `copy`.
-   **Sealed classes:** Use for closed type hierarchies so `when` can be
    exhaustive without an `else`.
-   **Extension functions:** Prefer to utility classes of static helpers. Keep
    them narrowly scoped.
-   **Visibility:** Declare the most restrictive visibility that works.
    `public` is the default and should not be written explicitly.
-   **Object expressions:** Prefer lambdas and SAM conversion to anonymous
    object expressions where the target is a functional interface.

## 5. Coroutines and Concurrency

-   **Suspend over callbacks:** Express asynchronous work as `suspend`
    functions rather than callback parameters.
-   **Structured concurrency:** Launch coroutines in a scope with a defined
    lifetime; never use `GlobalScope`.
-   **Injected dispatchers:** Pass dispatchers as constructor parameters
    rather than hardcoding them, so they can be replaced in tests.
-   **Main-safety:** A suspend function should be safe to call from any
    dispatcher; move blocking work with `withContext`.
-   **Cancellation:** Never swallow `CancellationException`; rethrow it.

## 6. Formatting

-   **Indentation:** Four spaces. **Do not use tabs.**
-   **Line length:** 100 characters maximum.
-   **Braces:** Required for `if` bodies spanning more than one line. A
    single-line `if` without `else` may omit them.
-   **Expression `when` branches:** Align branch bodies; use braces for
    multi-statement branches.
-   **One declaration per line.**

## 7. Documentation

-   **KDoc:** Use `/** ... */` for public API documentation.
-   **First sentence:** A single summary sentence, in its own paragraph.
-   **`@param` / `@return`:** Document them in prose when the summary is not
    self-explanatory; omit when redundant.
-   **Do not document the obvious.** Comments must add information.

*Sources:*

-   [Android Kotlin style guide](https://developer.android.com/kotlin/style-guide)
-   [Kotlin coding conventions](https://kotlinlang.org/docs/coding-conventions.html)
```

- [ ] **Step 4: Run verification to confirm it passes**

Run:
```bash
/tmp/check-guide.sh conductor/assets/code_styleguides/kotlin.md 120
grep -icE '\b(compose|@composable|activity|gradle|findviewbyid)\b|xml layout|android\.content|androidx\.' conductor/assets/code_styleguides/kotlin.md
```
Expected: `PASS: ... (N lines, budget 120)` and the grep count is `0`.

Note: this check targets Android *platform/API* terms (Compose, Activity,
Context, Gradle, XML layouts), not the word "android" itself. The file's
`*Sources:*` footer legitimately names "Android Kotlin style guide" as one of
its two upstream authorities — that citation is required, not a boundary
violation, and must not be removed.

If the grep is non-zero, remove the offending lines — the boundary rule is not negotiable.

- [ ] **Step 5: Commit**

```bash
git add conductor/assets/code_styleguides/kotlin.md
git commit -m "feat(styleguides): add Kotlin style guide"
```

---

### Task 2: Java style guide

**Files:**
- Create: `conductor/assets/code_styleguides/java.md`

**Interfaces:**
- Consumes: `/tmp/check-guide.sh` from Task 1 Step 1. If absent, recreate it from Task 1 Step 1 verbatim.
- Produces: the filename `java.md`, referenced by Task 5's guide list and bundle table.

- [ ] **Step 1: Run verification to confirm it fails**

Run: `/tmp/check-guide.sh conductor/assets/code_styleguides/java.md 110`
Expected: `FAIL: conductor/assets/code_styleguides/java.md does not exist`

- [ ] **Step 2: Write `java.md`**

Summarize from the Google Java Style Guide (google.github.io/styleguide/javaguide.html). Language rules only — no Android, Compose, Activity, or Gradle references.

Required structure (≤ 110 lines):

```markdown
# Google Java Style Guide Summary

This document summarizes key rules from the Google Java Style Guide.

## 1. Source File Basics

-   **Encoding:** Files are UTF-8.
-   **File name:** Matches the top-level class name, case-sensitively, with the
    `.java` extension.
-   **Ordering:** License or copyright, then `package`, then `import`s, then
    exactly one top-level class.
-   **Blank-line separation:** Each of the above sections is separated by one
    blank line.

## 2. Imports

-   **Wildcard imports:** **Do not use them**, static or otherwise.
-   **No line-wrapping:** Import statements are never wrapped.
-   **Ordering:** A single ASCII-sorted block of static imports, a blank line,
    then a single ASCII-sorted block of non-static imports.
-   **Static import for classes:** **Do not** statically import nested classes;
    import them normally.

## 3. Formatting

-   **Braces:** Required for `if`, `else`, `for`, `do`, and `while`, even when
    the body is empty or a single statement.
-   **Block style:** K&R — no line break before the opening brace; line break
    after it; line break before the closing brace.
-   **Indentation:** Two spaces per block level. Continuation lines indent at
    least four spaces.
-   **One statement per line.**
-   **Column limit:** 100 characters.
-   **Horizontal alignment:** Never required, and discouraged — it resists
    future edits.
-   **Variable declarations:** One variable per declaration; `int a, b;` is
    forbidden. Declare local variables close to first use.
-   **Array declarations:** C-style `String x[]` is forbidden; write
    `String[] x`.
-   **`switch` blocks:** Indent cases by two spaces. Every statement group
    either falls through with a `// fall through` comment or terminates. A
    `default` group is always present.
-   **Annotations:** One per line, immediately after the documentation block.
-   **Modifier order:** `public protected private abstract default static final
    transient volatile synchronized native strictfp`.

## 4. Naming

-   **Package names:** All lowercase, no underscores — `com.example.deepspace`.
-   **Class names:** `UpperCamelCase`, typically a noun or noun phrase. Test
    classes end in `Test`.
-   **Method names:** `lowerCamelCase`, typically a verb or verb phrase.
-   **Constant names:** `CONSTANT_CASE`, for `static final` fields whose
    contents are deeply immutable.
-   **Non-constant fields, parameters, local variables:** `lowerCamelCase`.
-   **Type variables:** A single capital letter, optionally followed by a digit
    (`T`, `E`, `T2`), or a class-like name suffixed with `T`.
-   **No special prefixes or suffixes:** `mName`, `s_name`, and `kValue` are
    forbidden.
-   **Camel case conversion:** Convert phrases to ASCII, remove apostrophes,
    split on spaces and hyphens, lowercase everything, then capitalize —
    yielding `supportsIpv6OnIos`, not `supportsIPv6OnIOS`.

## 5. Programming Practices

-   **`@Override`:** Always apply it when the method overrides a supertype
    method.
-   **Caught exceptions:** Never ignore silently. If ignoring is genuinely
    correct, explain why in a comment; in tests, the variable may be named
    `expected`.
-   **Static members:** Qualify with the class name, not an instance reference.
-   **Finalizers:** **Do not override `Object.finalize`.**
-   **Equality:** Override `hashCode` whenever `equals` is overridden.

## 6. Javadoc

-   **Format:** A `/** ... */` block; the first line is a single summary
    fragment ending in a period.
-   **Block tags:** In the order `@param`, `@return`, `@throws`,
    `@deprecated`, each with a non-empty description.
-   **Required for:** Every public class and every public or protected member.
-   **Exceptions:** Self-explanatory members and overrides may omit it.
-   **Summary fragment:** A noun or verb phrase, not a complete sentence —
    "Returns the customer ID," not "This method returns the customer ID."

*Source:
[Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)*
```

- [ ] **Step 3: Run verification to confirm it passes**

Run:
```bash
/tmp/check-guide.sh conductor/assets/code_styleguides/java.md 110
grep -icE '\b(compose|@composable|activity|gradle|findviewbyid)\b|xml layout|android\.content|androidx\.' conductor/assets/code_styleguides/java.md
```
Expected: `PASS: ...` and grep count `0`. (This file's own citation is purely
"Google Java Style Guide," so it does not need the citation exemption Task 1
required, but the same platform/API term list is used for consistency.)

- [ ] **Step 4: Commit**

```bash
git add conductor/assets/code_styleguides/java.md
git commit -m "feat(styleguides): add Java style guide"
```

---

### Task 3: Android platform style guide

**Files:**
- Create: `conductor/assets/code_styleguides/android.md`

**Interfaces:**
- Consumes: `/tmp/check-guide.sh` from Task 1 Step 1.
- Produces: the filename `android.md`, referenced by Task 5's guide list and bundle table.

**Constraint reminder:** No Kotlin-vs-Java syntax rules (those live in Tasks 1–2). No Compose rules (Task 4). Diff-verifiable rules first; architectural guidance last, in a labelled section.

- [ ] **Step 1: Run verification to confirm it fails**

Run: `/tmp/check-guide.sh conductor/assets/code_styleguides/android.md 130`
Expected: `FAIL: ... does not exist`

- [ ] **Step 2: Write `android.md`**

Summarize from the Android developer guides (app resources, manifest, activity lifecycle, app architecture). Required structure (≤ 130 lines):

```markdown
# Android Platform Style Guide

This document summarizes conventions from the Android developer guides for
resources, layouts, the manifest, and component lifecycles. Language-level
rules live in the Kotlin and Java guides; Compose rules live in the Compose
guide.

## 1. Resource Naming

-   **Pattern:** `<what>_<where>_<description>_<size>`, lowercase with
    underscores. Resource names may not contain hyphens or capitals.
-   **Layouts:** Prefix by component type — `activity_main.xml`,
    `fragment_profile.xml`, `item_contact.xml`, `view_badge.xml`,
    `dialog_confirm.xml`.
-   **Drawables:** Describe the asset — `ic_arrow_back`, `bg_toolbar`,
    `divider_horizontal`. Vector icons use the `ic_` prefix.
-   **IDs:** Name by role, not by type — `@+id/submit_button`, not
    `@+id/button1`.
-   **Strings:** Group by screen or feature — `profile_title`,
    `profile_error_network`.
-   **Dimensions:** Semantic, not literal — `spacing_medium`, not `margin_16`.
-   **Styles and themes:** `UpperCamelCase` with dot-separated extension —
    `Widget.App.Button`, `Theme.App`.

## 2. Layout XML

-   **No hardcoded strings.** All user-facing text is a `@string` reference, so
    it can be translated.
-   **No hardcoded dimensions.** Spacing, sizes, and radii reference
    `@dimen` values.
-   **No hardcoded colors.** Reference `@color` or a theme attribute
    (`?attr/colorPrimary`) so dark mode and theming work.
-   **`sp` for text, `dp` for everything else.** Text sizes use `sp` so they
    honor the user's font-scale accessibility setting; all other dimensions
    use `dp`. Never use `px`.
-   **Attribute order:** `android:id`, then `layout_width` and
    `layout_height`, then other `layout_*` attributes, then remaining
    attributes, then `style`.
-   **`match_parent` over `fill_parent`.** `fill_parent` is deprecated.
-   **Avoid deep nesting.** Prefer `ConstraintLayout` to nested
    `LinearLayout`s; nesting weighted `LinearLayout`s forces multiple measure
    passes.
-   **`tools:` attributes for preview data.** Use `tools:text` for sample
    content so it never ships; `android:text` placeholders do ship.
-   **`contentDescription`:** Required on every non-decorative `ImageView` and
    `ImageButton`. Set `android:importantForAccessibility="no"` on purely
    decorative images.
-   **Touch targets:** Interactive views are at least `48dp` in both
    dimensions.
-   **`start`/`end` over `left`/`right`.** Use
    `layout_marginStart`/`layout_marginEnd` and `paddingStart`/`paddingEnd` so
    right-to-left locales lay out correctly.
-   **`<merge>` and `<include>`:** Use to reuse layout fragments and to
    eliminate a redundant wrapper when including.

## 3. Resource Organization

-   **No default-bucket-only drawables for density-dependent assets.** Provide
    the needed density buckets, or use a vector drawable.
-   **Configuration qualifiers:** Place alternatives in qualified directories
    (`values-night/`, `values-sw600dp/`, `values-es/`) rather than branching in
    code.
-   **Plurals:** Use `<plurals>` with quantity keys; never concatenate a count
    into a singular string.
-   **String formatting:** Use positional placeholders (`%1$s`) so translators
    can reorder them.

## 4. Manifest

-   **Declare the minimum permissions required.** Remove permissions no longer
    used.
-   **`exported`:** Set explicitly on every component with an intent filter.
-   **No secrets.** API keys and credentials do not belong in the manifest or
    in version-controlled resources.
-   **`android:allowBackup`:** Set deliberately; consider what data would be
    included.
-   **Avoid hardcoded `versionCode`/`versionName` drift.** Keep them in the
    build configuration, not duplicated in the manifest.

## 5. Lifecycle Correctness

-   **No long-lived `Context` references.** Never store an `Activity` or
    `View` in a static field, a singleton, or an object outliving the
    component; this leaks the whole view hierarchy.
-   **`applicationContext` for long-lived needs.** Use it when the reference
    outlives the current screen; use the `Activity` context for UI inflation
    and dialogs.
-   **Release in the mirrored callback.** Resources acquired in `onStart` are
    released in `onStop`; those acquired in `onCreate` are released in
    `onDestroy`.
-   **Unregister what you register.** Listeners, receivers, and observers
    registered manually must be unregistered, or scoped to a lifecycle owner
    that does it.
-   **Close what you open.** `Cursor`s, streams, and database connections are
    closed, preferably with a use-scoped construct.
-   **No `findViewById` after the view is destroyed.** Null out binding
    references in a fragment's `onDestroyView`.

## 6. Architectural Guidance

The rules below require design judgment and cannot be verified from a diff
alone. Treat them as review discussion points rather than mechanical checks.

-   **Separate UI, domain, and data layers.** UI observes state; it does not
    perform I/O directly.
-   **Single source of truth per datum.** Each piece of state is owned by one
    layer, and other layers observe it.
-   **Survive configuration change and process death.** State needed after
    rotation belongs in a `ViewModel`; state needed after process death belongs
    in saved state or persistent storage.
-   **Keep business logic out of lifecycle callbacks.** `Activity` and
    `Fragment` classes coordinate; they do not implement rules.
-   **Expose immutable state upward.** Publish read-only observable state and
    keep the mutable holder private.

*Sources:*

-   [App resources overview](https://developer.android.com/guide/topics/resources/providing-resources)
-   [App manifest overview](https://developer.android.com/guide/topics/manifest/manifest-intro)
-   [Activity lifecycle](https://developer.android.com/guide/components/activities/activity-lifecycle)
-   [Guide to app architecture](https://developer.android.com/topic/architecture)
```

- [ ] **Step 3: Run verification to confirm it passes**

Run:
```bash
/tmp/check-guide.sh conductor/assets/code_styleguides/android.md 130
echo "--- compose leakage (expect 0) ---"
grep -icE '@composable|recomposition|remember\(|modifier' conductor/assets/code_styleguides/android.md
echo "--- language-syntax leakage (expect 0) ---"
grep -icE '\blateinit\b|!!|suspend fun|@Override' conductor/assets/code_styleguides/android.md
echo "--- architectural section present (expect 1) ---"
grep -c '^## 6. Architectural Guidance' conductor/assets/code_styleguides/android.md
```
Expected: `PASS`, `0`, `0`, `1`.

Note: the language-syntax check targets terms that are unambiguously
Kotlin/Java *code* syntax (`lateinit`, `!!`, `suspend fun`, `@Override`). It
deliberately does not match "UpperCamelCase" or "lowerCamelCase" as bare
words, because `android.md` legitimately uses "UpperCamelCase" to describe
Android *resource and style naming* (e.g. `Theme.App.Button`) — a casing
pattern name shared across many contexts, not a leaked Kotlin/Java
identifier-naming rule.

- [ ] **Step 4: Commit**

```bash
git add conductor/assets/code_styleguides/android.md
git commit -m "feat(styleguides): add Android platform style guide"
```

---

### Task 4: Jetpack Compose style guide

**Files:**
- Create: `conductor/assets/code_styleguides/compose.md`

**Interfaces:**
- Consumes: `/tmp/check-guide.sh` from Task 1 Step 1.
- Produces: the filename `compose.md`, referenced by Task 5's guide list and bundle table.

**Constraint reminder:** No XML or View-system rules. Stable fundamentals only — nothing experimental or version-pinned, since this is the fastest-aging content in the set.

- [ ] **Step 1: Run verification to confirm it fails**

Run: `/tmp/check-guide.sh conductor/assets/code_styleguides/compose.md 110`
Expected: `FAIL: ... does not exist`

- [ ] **Step 2: Write `compose.md`**

Summarize from the Compose documentation and the Compose API guidelines. Required structure (≤ 110 lines):

```markdown
# Jetpack Compose Style Guide

This document summarizes conventions from the Jetpack Compose documentation and
the Compose API guidelines. Compose is Kotlin-only; general Kotlin rules live
in the Kotlin guide.

## 1. Naming

-   **Composable functions:** `PascalCase` noun phrases describing what they
    emit — `ProfileCard`, `SubmitButton`. A `@Composable` function that emits
    UI is named like a type, not like a verb.
-   **Return no value when emitting.** A composable that emits UI returns
    `Unit`. Composables that return a value are named `lowerCamelCase` like
    normal functions — `rememberScrollState`.
-   **`remember` factories:** Prefix with `remember` when the function returns
    a remembered object — `rememberNavController`.
-   **Preview functions:** Suffix with `Preview` and mark them `private`.
-   **Slot parameters:** Name trailing composable lambdas `content`.

## 2. Parameters

-   **`modifier` is the first optional parameter.** Every composable that emits
    UI accepts a `modifier: Modifier = Modifier` as its first parameter with a
    default.
-   **Apply `modifier` to the outermost layout.** The caller's modifier must
    reach the root node of what the composable emits, exactly once.
-   **Parameter order:** Required parameters, then `modifier`, then optional
    parameters, then a trailing `content` lambda.
-   **Do not accept a `Modifier` for internal children.** Only one `modifier`
    parameter per composable.
-   **Hoist state, do not accept mutable holders.** Accept a value plus an
    `onValueChange` callback rather than a `MutableState`.

## 3. State and Recomposition

-   **`remember` for values that must survive recomposition.** Unremembered
    allocations are recreated on every recomposition.
-   **`rememberSaveable` for values that must survive configuration change.**
-   **Specify `remember` keys.** Pass every input the computation depends on as
    a key; a `remember` with a stale key returns a stale value, and a
    `remember(Unit)` that depends on a parameter is a defect.
-   **`derivedStateOf` for values computed from other state** when the
    computation is expensive relative to how often its inputs change.
-   **No side effects in the composable body.** A composable may run any number
    of times, in any order, on any thread, and may be skipped. Use
    `LaunchedEffect`, `SideEffect`, or `DisposableEffect`.
-   **Key `LaunchedEffect` correctly.** `LaunchedEffect(Unit)` runs once per
    composition entry; keying on changing values restarts it.
-   **Clean up in `DisposableEffect`.** Registrations made in an effect are
    removed in its `onDispose`.
-   **Never mutate state during composition.** Writing to state in the
    composable body can loop recomposition indefinitely.

## 4. Modifiers

-   **Order is semantic, not cosmetic.** `Modifier.padding(8.dp).background(c)`
    and `Modifier.background(c).padding(8.dp)` render differently; the first
    pads outside the background, the second inside it.
-   **`clickable` placement determines the touch target.** Apply it before
    `padding` to include the padding in the clickable area.
-   **`size` before `padding`** constrains the outer bounds;
    `padding` before `size` shrinks the content.
-   **Chain, do not nest wrappers.** Prefer modifier chaining to extra `Box`
    layouts for padding, size, and background.
-   **Do not pass a modifier through to multiple children.** Reusing one
    modifier instance on several nodes applies its effects repeatedly.

## 5. Structure and Performance

-   **Keep composables small and focused.** One composable, one piece of UI.
-   **Separate stateful from stateless.** Provide a stateless composable taking
    values and callbacks, plus a thin stateful wrapper that hoists state. The
    stateless one is previewable and testable.
-   **Provide keys in lazy lists.** Pass a stable `key` to `items` so
    reordering preserves item state and scroll position.
-   **Do not read state higher than needed.** Reading a frequently-changing
    value in a parent recomposes the whole subtree; read it in the smallest
    composable that needs it, or pass a lambda.
-   **Defer reads with lambdas.** Pass `() -> Float` rather than `Float` for
    rapidly changing values such as scroll offset or animation progress.
-   **Avoid non-skippable parameters.** Unstable parameter types prevent
    Compose from skipping recomposition; prefer immutable types and stable
    collections.

## 6. Theming and Accessibility

-   **Read colors, typography, and shapes from the theme.** Do not hardcode
    color or text-size literals in composables.
-   **`contentDescription` on every meaningful image or icon.** Pass `null`
    only for purely decorative content.
-   **Minimum touch target of 48dp** for interactive composables.
-   **`sp` for text sizes, `dp` for layout dimensions.**

## 7. Architectural Guidance

The rules below require design judgment and cannot be verified from a diff
alone. Treat them as review discussion points rather than mechanical checks.

-   **Hoist state to the lowest common ancestor that needs it.** State lives at
    the highest point it is read and the lowest point it can be owned.
-   **Unidirectional data flow.** State flows down; events flow up as
    callbacks.
-   **Composables observe state; they do not fetch it.** Data loading belongs
    outside the composition.
-   **One state holder per screen.** Expose a single immutable UI state object
    rather than many unrelated observable values.

*Sources:*

-   [Compose documentation](https://developer.android.com/develop/ui/compose/documentation)
-   [Compose API guidelines](https://android.googlesource.com/platform/frameworks/support/+/androidx-main/compose/docs/compose-api-guidelines.md)
-   [State and Jetpack Compose](https://developer.android.com/develop/ui/compose/state)
```

- [ ] **Step 3: Run verification to confirm it passes**

Run:
```bash
/tmp/check-guide.sh conductor/assets/code_styleguides/compose.md 110
echo "--- XML/View leakage (expect 0) ---"
grep -icE 'findViewById|ConstraintLayout|LinearLayout|\.xml|@\+id|match_parent|android:' conductor/assets/code_styleguides/compose.md
echo "--- architectural section present (expect 1) ---"
grep -c '^## 7. Architectural Guidance' conductor/assets/code_styleguides/compose.md
```
Expected: `PASS`, `0`, `1`.

- [ ] **Step 4: Commit**

```bash
git add conductor/assets/code_styleguides/compose.md
git commit -m "feat(styleguides): add Jetpack Compose style guide"
```

---

### Task 5: Guide list and Android bundle rule (Edit B)

**Files:**
- Modify: `.opencode/command/setup.md:58-71` (section `## 6. Code Style Guides`)

**Interfaces:**
- Consumes: the four filenames from Tasks 1–4 (`kotlin.md`, `java.md`, `android.md`, `compose.md`).
- Produces: the amended available-guides list that Task 9's V5 check compares against `ls`.

- [ ] **Step 1: Write the consistency check first**

Create `/tmp/check-guide-list.sh` (scratch, not committed):

```bash
#!/bin/bash
# Asserts the guide names listed in setup.md match the files on disk.
disk=$(ls conductor/assets/code_styleguides/*.md | xargs -n1 basename | sed 's/\.md$//' | sort | tr '\n' ' ')
listed=$(grep -o 'Available guides:.*' .opencode/command/setup.md \
  | sed 's/Available guides: //; s/`//g; s/\.$//' \
  | tr ',' '\n' | sed 's/^ *//; s/ *$//' | sort | tr '\n' ' ')
echo "disk:   $disk"
echo "listed: $listed"
[ "$disk" = "$listed" ] && echo "PASS: lists match" || { echo "FAIL: mismatch"; exit 1; }
```

```bash
chmod +x /tmp/check-guide-list.sh
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `/tmp/check-guide-list.sh`
Expected: `FAIL: mismatch` — disk has 13 entries (after Tasks 1–4), `setup.md` still lists 9.

- [ ] **Step 3: Replace the available-guides line**

In `.opencode/command/setup.md`, find this line (currently line 60):

```
The bundled guides live at `~/.config/opencode/command/conductor/assets/code_styleguides/`. Available guides: `cpp`, `csharp`, `dart`, `general`, `go`, `html-css`, `javascript`, `python`, `typescript`.
```

Replace with:

```
The bundled guides live at `~/.config/opencode/command/conductor/assets/code_styleguides/`. Available guides: `android`, `compose`, `cpp`, `csharp`, `dart`, `general`, `go`, `html-css`, `java`, `javascript`, `kotlin`, `python`, `typescript`.
```

- [ ] **Step 4: Run the check to confirm it passes**

Run: `/tmp/check-guide-list.sh`
Expected: `PASS: lists match`

- [ ] **Step 5: Add the Android bundle rule**

In the same section, immediately after the numbered item that currently reads "1. Recommend the guides that match the confirmed tech stack (always include `general`). Do NOT invent style rules — only copy from the bundled assets.", insert:

```markdown
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
```

- [ ] **Step 6: Verify the section reads coherently**

Run: `sed -n '55,95p' .opencode/command/setup.md`
Expected: the available-guides line lists 13 names; the bundle table and both guards appear inside item 1 of the numbered list; items 2, 3, and 4 still follow in order and still make sense.

- [ ] **Step 7: Commit**

```bash
git add .opencode/command/setup.md
git commit -m "feat(setup): add Android guides to the list and bundle recommendation"
```

---

### Task 6: Gradle brownfield detection (Edits C, D, E)

**Files:**
- Modify: `.opencode/command/setup.md:31` (brownfield indicators), `:34` (scan instructions)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: the Gradle-aware maturity detection that Task 7's Edit F/G rely on for brownfield inference.

- [ ] **Step 1: Confirm the current state**

Run: `grep -n 'Brownfield indicators' .opencode/command/setup.md`
Expected: one match at line 31, listing `package.json`, `go.mod`, `requirements.txt`, `pom.xml`, `Cargo.toml` and **no Gradle file**.

- [ ] **Step 2: Add Gradle indicators (Edit C)**

In `.opencode/command/setup.md` line 31, find:

```
- **Brownfield indicators:** dependency manifests (`package.json`, `go.mod`, `requirements.txt`, `pom.xml`, `Cargo.toml`), source directories
```

Replace that fragment with:

```
- **Brownfield indicators:** dependency manifests (`package.json`, `go.mod`, `requirements.txt`, `pom.xml`, `Cargo.toml`, `build.gradle`, `build.gradle.kts`, `settings.gradle`, `settings.gradle.kts`), an `AndroidManifest.xml` anywhere in the tree, source directories
```

Leave the rest of the line — the `src/`/`app/`/`lib/`/`bin/` list, the `.git` check, the `git status --porcelain` instruction, and the uncommitted-changes warning — exactly as it is.

- [ ] **Step 3: Add Gradle inference and exclusions (Edits D, E)**

Find the Brownfield scan paragraph at line 34:

```
**If Brownfield:** ask permission for a read-only scan. On approval, analyze efficiently: use `git ls-files`, respect `.gitignore`, skip `node_modules`/`dist`/`build`, and read `README.md` plus manifests to infer the tech stack and architecture. Hold the findings in context.
```

Replace with:

```
**If Brownfield:** ask permission for a read-only scan. On approval, analyze efficiently: use `git ls-files`, respect `.gitignore`, skip `node_modules`/`dist`/`build`/`.gradle`/`.cxx`, and read `README.md` plus manifests to infer the tech stack and architecture. Hold the findings in context.

For Gradle projects, also read `build.gradle[.kts]`, `settings.gradle[.kts]`, and `gradle/libs.versions.toml` to infer the language, `compileSdk`/`minSdk`, and whether Compose is enabled — a `buildFeatures { compose true }` block, an `androidx.compose` BOM dependency, or the `org.jetbrains.kotlin.plugin.compose` plugin each answer the UI-toolkit question directly. Read the `include(...)` entries in `settings.gradle[.kts]` to list the project's modules. Hold all of this in context; steps 5 and 6 record it.
```

- [ ] **Step 4: Verify both edits landed**

Run:
```bash
echo "--- Gradle indicators (expect 4 gradle names + manifest) ---"
grep -c -e 'build.gradle' -e 'settings.gradle' -e 'AndroidManifest.xml' .opencode/command/setup.md
echo "--- exclusions include .gradle and .cxx (expect 1) ---"
grep -c 'node_modules`/`dist`/`build`/`.gradle`/`.cxx' .opencode/command/setup.md
echo "--- inference paragraph present (expect 1) ---"
grep -c 'libs.versions.toml' .opencode/command/setup.md
echo "--- no Android branch leaked into other commands (expect 0) ---"
grep -icE 'android|gradle' .opencode/command/new-track.md .opencode/command/implement.md .opencode/command/review.md | grep -v ':0' || echo "0 (clean)"
```
Expected: non-zero counts for the first three; the last prints `0 (clean)`.

- [ ] **Step 5: Commit**

```bash
git add .opencode/command/setup.md
git commit -m "feat(setup): detect Gradle and Android projects as brownfield"
```

---

### Task 7: UI toolkit question, verification commands, module layout (Edits A, F, G)

**Files:**
- Modify: `.opencode/command/setup.md:51-56` (section `## 5. Technology Stack`)

**Interfaces:**
- Consumes: the Gradle inference added in Task 6 Step 3 (brownfield projects infer the toolkit instead of asking blind); the bundle table from Task 5 Step 5 keys off the UI toolkit this task records.
- Produces: a `tech-stack.md` containing a **Verification Commands** section and, for multi-module projects, a **Modules** section.

- [ ] **Step 1: Confirm the current state**

Run: `sed -n '51,57p' .opencode/command/setup.md`
Expected: three numbered items — the Greenfield/Brownfield branch, the Approve/Manual Edit/Refine loop, and "Write `conductor/tech-stack.md`". No UI-toolkit question and no verification commands.

- [ ] **Step 2: Add the UI-toolkit question (Edit A)**

In item 1 of section 5, after the sentence ending `...Frontend Framework(s), and Database.`, append:

```
If the stack targets Android, also ask a single-choice **UI toolkit** question: **Jetpack Compose** `(Recommended)` — the current Android UI toolkit; **XML layouts (Views)** — the classic toolkit; or **Both** — a project migrating between them.
```

Then, in the **Brownfield** sentence of item 1, after `...ask an open question for the correct stack.`, append:

```
For an Android project, state the UI toolkit inferred from the build files (see step 2's Gradle inference) and confirm it rather than asking blind.
```

- [ ] **Step 3: Add verification commands and modules (Edits F, G)**

Replace item 3 of section 5 — currently `3. Write `conductor/tech-stack.md`.` — with:

```markdown
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
```

- [ ] **Step 4: Verify the section**

Run:
```bash
echo "--- UI toolkit question (expect 1) ---"
grep -c 'UI toolkit' .opencode/command/setup.md
echo "--- verification commands (expect >=1) ---"
grep -c 'Verification Commands' .opencode/command/setup.md
echo "--- instrumented distinction (expect 1) ---"
grep -c 'connectedAndroidTest' .opencode/command/setup.md
echo "--- section 5 numbering is 1..5 sequential ---"
sed -n '/^## 5. Technology Stack/,/^## 6. Code Style Guides/p' .opencode/command/setup.md | grep -oE '^[0-9]+\.' 
echo "--- section 6 still intact (expect 1) ---"
grep -c '^## 6. Code Style Guides' .opencode/command/setup.md
```
Expected: counts ≥1; the numbering output is exactly `1.` `2.` `3.` `4.` `5.` in order; section 6 still present.

- [ ] **Step 5: Confirm the resume list still matches**

`setup.md:25` lists the resume order: Product Definition, Product Guidelines, Technology Stack, Code Style Guides, Workflow. This task added sub-items to Technology Stack but no new top-level artifact, so the resume list needs no change.

Run: `grep -n 'Resume at the first missing artifact' .opencode/command/setup.md`
Expected: one match; read it and confirm the five-artifact order is still accurate.

- [ ] **Step 6: Commit**

```bash
git add .opencode/command/setup.md
git commit -m "feat(setup): record UI toolkit, verification commands, and modules"
```

---

### Task 8: Close two general enforcement gaps (Edit H)

**Files:**
- Modify: `conductor/assets/workflow-template.md:14-22` (the enforcement table)

**Interfaces:**
- Consumes: nothing.
- Produces: enforcement rows covering pure presentation-layer logic and infrastructure-dependent data-layer tasks, which `new-track` uses when tagging and `implement` uses when enforcing.

**Constraint reminder:** Platform-neutral wording only. No Android, Gradle, ViewModel, Room, or Compose terms. This is a general taxonomy fix; Android is only the motivating example.

- [ ] **Step 1: Confirm the current table and the absence of a committed marker**

Run:
```bash
sed -n '14,22p' conductor/assets/workflow-template.md
echo "--- committed marker (expect 0) ---"
grep -c 'conductor-workflow-version' conductor/assets/workflow-template.md
```
Expected: the 7-row table; marker count `0`. **The `0` is correct and must stay `0`** — `install.sh:42` appends the marker at install time, so committing one would produce a duplicate.

- [ ] **Step 2: Amend the `frontend-ui` component-logic row**

In `conductor/assets/workflow-template.md`, find:

```
| `frontend-ui` — component logic (state, handlers, computed values) | **Test-after** (test-first optional) | Logic is testable but often clarified while building |
```

Replace with these two rows:

```
| `frontend-ui` — presentation logic that is pure and runs without a UI host (state holders, reducers, view models, formatters) | **Strict test-first** | Contract is knowable up front and the code runs in a plain test process; the same reasoning as `backend-logic` |
| `frontend-ui` — component logic bound to a rendered component (handlers, computed values read from the view) | **Test-after** (test-first optional) | Logic is testable but often clarified while building |
```

- [ ] **Step 3: Amend the `backend-logic` row for infrastructure-dependent tasks**

Find:

```
| `backend-logic` (services, business logic, utility functions) | **Strict test-first** | Contract is knowable up front; test-first improves interface design |
```

Replace with these two rows:

```
| `backend-logic` (services, business logic, utility functions) | **Strict test-first** | Contract is knowable up front; test-first improves interface design |
| `backend-logic` — requires external infrastructure to test (a real database, device, container, or network service) | **Test-first on the parts testable in-process; infrastructure-dependent tests deferred to the track-level pass** | The contract is still knowable, but demanding infrastructure per task blocks tasks for environmental reasons rather than code defects |
```

- [ ] **Step 4: Add the coverage-expectation exception**

In the `## Coverage expectations` section, find:

```
- Every `backend-logic` and `api-client` task must have at least one
  passing unit test before the task is marked complete.
```

Replace with:

```
- Every `backend-logic` and `api-client` task must have at least one
  passing unit test before the task is marked complete. The one exception
  is a `backend-logic` task marked as requiring external infrastructure:
  its in-process tests must pass per task, and its
  infrastructure-dependent tests are validated at track level alongside
  `e2e-flow`.
```

- [ ] **Step 5: Verify platform neutrality and structure**

Run:
```bash
echo "--- platform terms (expect 0) ---"
grep -icE 'android|gradle|viewmodel|jetpack|compose|room|espresso|kotlin' conductor/assets/workflow-template.md
echo "--- table row count (expect 9) ---"
awk '/^\| Task type/,/^$/' conductor/assets/workflow-template.md | grep -c '^| `'
echo "--- marker still absent (expect 0) ---"
grep -c 'conductor-workflow-version' conductor/assets/workflow-template.md
echo "--- table still well-formed: every row has 3 cells ---"
awk '/^\| `/ {n=gsub(/\|/,"|"); if (n != 4) print "BAD ROW "NR": "n" pipes"}' conductor/assets/workflow-template.md || true
echo "--- coverage exception present (expect 1) ---"
grep -c 'infrastructure-dependent tests are validated at track level' conductor/assets/workflow-template.md
```
Expected: `0`, `9`, `0`, no `BAD ROW` output, `1`.

If the platform-terms count is non-zero, the wording violates the constraint — rewrite it generically.

- [ ] **Step 6: Commit**

```bash
git add conductor/assets/workflow-template.md
git commit -m "fix(workflow): close two task-type enforcement gaps

Pure presentation-layer logic (state holders, reducers, view models) is
unit-testable with a knowable contract, so it is enforced test-first
rather than demoted to test-after. Data-layer tasks requiring external
infrastructure enforce test-first on their in-process portion, with
infrastructure-dependent tests deferred to the track-level pass."
```

---

### Task 9: Full-system verification

**Files:**
- Modify: none. This task only verifies.

**Interfaces:**
- Consumes: every artifact from Tasks 1–8.
- Produces: evidence that the change is complete and the installer works.

- [ ] **Step 1: Verify all four guides against format and budget**

Run:
```bash
/tmp/check-guide.sh conductor/assets/code_styleguides/kotlin.md 120
/tmp/check-guide.sh conductor/assets/code_styleguides/java.md 110
/tmp/check-guide.sh conductor/assets/code_styleguides/android.md 130
/tmp/check-guide.sh conductor/assets/code_styleguides/compose.md 110
```
Expected: four `PASS` lines. (Covers V2, V3.)

- [ ] **Step 2: Verify the boundary rule across all four files**

Run:
```bash
echo "--- kotlin/java must not mention the platform (expect 0 0) ---"
grep -icE '\b(compose|@composable|activity|gradle|findviewbyid)\b|xml layout|android\.content|androidx\.' conductor/assets/code_styleguides/kotlin.md
grep -icE '\b(compose|@composable|activity|gradle|findviewbyid)\b|xml layout|android\.content|androidx\.' conductor/assets/code_styleguides/java.md
# Note: kotlin.md's *Sources:* footer legitimately names "Android Kotlin
# style guide" as an upstream authority. This check targets platform/API
# terms, not the word "android" itself, so that citation does not trip it.
echo "--- android.md must not contain Compose or language-syntax rules (expect 0 0) ---"
grep -icE '@composable|recomposition|modifier' conductor/assets/code_styleguides/android.md
grep -icE '\blateinit\b|@Override' conductor/assets/code_styleguides/android.md
echo "--- compose.md must not contain XML/View rules (expect 0) ---"
grep -icE 'findViewById|ConstraintLayout|LinearLayout|@\+id|match_parent|android:' conductor/assets/code_styleguides/compose.md
```
Expected: all zeros. (Covers V4.)

- [ ] **Step 3: Verify the guide list matches disk**

Run: `/tmp/check-guide-list.sh`
Expected: `PASS: lists match`, with 13 names on both sides. (Covers V5.)

- [ ] **Step 4: Run the real installer into a sandbox**

```bash
SANDBOX=$(mktemp -d)
mkdir -p "$SANDBOX/run"
cd "$SANDBOX/run"
HOME="$SANDBOX" /Users/dt105/git/playground/conductor2/install.sh
echo "--- guide count (expect 13) ---"
ls "$SANDBOX/.config/opencode/command/conductor/assets/code_styleguides/" | wc -l
echo "--- the four new files present (expect 4) ---"
ls "$SANDBOX/.config/opencode/command/conductor/assets/code_styleguides/" | grep -cE '^(kotlin|java|android|compose)\.md$'
echo "--- installed template has exactly one marker, as the last line (expect 1 and a marker) ---"
grep -c 'conductor-workflow-version' "$SANDBOX/.config/opencode/command/conductor/assets/workflow-template.md"
tail -1 "$SANDBOX/.config/opencode/command/conductor/assets/workflow-template.md"
cd /Users/dt105/git/playground/conductor2
rm -rf "$SANDBOX"
```
Expected: `13`, `4`, `1`, and a last line matching `<!-- conductor-workflow-version: <sha> -->`. (Covers V1, V8.)

- [ ] **Step 5: Verify no platform logic leaked into the other commands**

Run:
```bash
grep -icE 'android|gradle|kotlin|compose' .opencode/command/new-track.md .opencode/command/implement.md .opencode/command/review.md conductor/assets/workflow-template.md skill/SKILL.md
```
Expected: `:0` for every file. (Covers V9 and the platform-neutrality constraint.)

- [ ] **Step 6: Review the full diff**

Run: `git diff --stat fb9a5eb..HEAD && git log --oneline fb9a5eb..HEAD`
Expected: 4 new guide files, `setup.md` modified, `workflow-template.md` modified, plus the two spec commits. **`install.sh` must be unchanged** — confirm it does not appear in the diffstat.

- [ ] **Step 7: Confirm spec coverage**

Read `docs/superpowers/specs/2026-10-06-android-style-guides-design.md` and confirm each of Edits A–H maps to a completed task: A and F and G → Task 7, B → Task 5, C and D and E → Task 6, H → Task 8, Edit I → withdrawn, no work required. Gaps 1–4 from the Problem section are each closed.

- [ ] **Step 8: Commit nothing; report**

This task produces no commit. Report the verification output.

---

## Self-Review

**Spec coverage:** Edit A → Task 7 Step 2. Edit B → Task 5 Steps 3, 5. Edit C → Task 6 Step 2. Edit D → Task 6 Step 3. Edit E → Task 6 Step 3. Edit F → Task 7 Step 3. Edit G → Task 7 Step 3. Edit H → Task 8 Steps 2–4. Edit I → withdrawn in the spec; Task 8 Step 1 and Task 9 Step 4 assert the marker stays uncommitted and is generated once at install. Four guide files → Tasks 1–4. V1–V9 → Task 9. All four Problem-section gaps are closed.

**Placeholder scan:** No TBD/TODO. Every file to create has its full content inline. Every verification step names an exact command and its expected output. No step says "similar to Task N" — the boundary-grep commands are repeated in full where needed.

**Type consistency:** Filenames `kotlin.md`, `java.md`, `android.md`, `compose.md` are used identically in Tasks 1–4, the Task 5 guide list and bundle table, and the Task 9 checks. `/tmp/check-guide.sh` takes `<file> <max_lines>` and is called that way in all five places. Budgets 120/110/130/110 match the Global Constraints and the spec. The section heading numbers asserted in Tasks 3 and 4 (`## 6. Architectural Guidance`, `## 7. Architectural Guidance`) match the content written in those same tasks.
