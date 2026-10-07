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

-   [App resources overview][android-resources]
-   [App manifest overview][android-manifest]
-   [Activity lifecycle][android-lifecycle]
-   [Guide to app architecture][android-architecture]

[android-resources]: https://developer.android.com/guide/topics/resources/providing-resources
[android-manifest]: https://developer.android.com/guide/topics/manifest/manifest-intro
[android-lifecycle]: https://developer.android.com/guide/components/activities/activity-lifecycle
[android-architecture]: https://developer.android.com/topic/architecture
