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
