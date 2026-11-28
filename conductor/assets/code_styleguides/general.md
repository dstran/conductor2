# General Code Style Principles

This document outlines general coding principles that apply across all languages
and frameworks used in this project.

## Readability

-   Read code from the caller's perspective. Use names that make the value,
    responsibility, and effects clear where they are used.
-   Prefer straightforward control flow and remove needless indirection when
    doing so makes the behavior easier to follow.
-   Avoid overly clever or obscure constructs. Keep useful API documentation;
    comments should explain intent, constraints, or non-obvious behavior rather
    than repeat what the code already says.
-   Prefer idioms supported by the project's declared language and toolchain
    versions. Do not introduce a newer construct without confirming support.

## Consistency

-   Follow existing patterns in the codebase.
-   Maintain consistent formatting, naming, and structure.

## Simplicity

-   Prefer simple solutions over complex ones.
-   Break down complex problems into smaller, manageable parts.

## Maintainability

-   Write code that is easy to modify and extend.
-   Minimize dependencies and coupling.
-   Introduce an abstraction or design pattern only when it addresses a concrete
    need in the current code. Do not add structure solely in anticipation of
    hypothetical future requirements.

## Documentation

-   Document *why* something is done, not just *what*.
-   Keep documentation up-to-date with code changes.
