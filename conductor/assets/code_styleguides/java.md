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
