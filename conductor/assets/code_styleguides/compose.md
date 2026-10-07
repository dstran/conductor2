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

-   [Compose documentation][compose-docs]
-   [Compose API guidelines][compose-api-guidelines]
-   [State and Jetpack Compose][compose-state]

[compose-docs]: https://developer.android.com/develop/ui/compose/documentation
[compose-api-guidelines]: https://android.googlesource.com/platform/frameworks/support/+/androidx-main/compose/docs/compose-api-guidelines.md
[compose-state]: https://developer.android.com/develop/ui/compose/state
