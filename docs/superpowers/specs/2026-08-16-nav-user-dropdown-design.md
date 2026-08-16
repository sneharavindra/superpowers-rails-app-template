# Collapse nav user info into a dropdown

## Problem

The nav currently shows the avatar, email address, and "Sign out" button as three separate inline elements. The user wants these collapsed into a single dropdown, triggered by the avatar, using icons.

## Design

**Trigger:** The avatar (`avatar avatar-placeholder` circle) becomes a DaisyUI dropdown trigger, using the `details`/`summary` dropdown pattern (no JS/Stimulus needed — matches this app's existing "no build step, push logic to the server" frontend approach).

**Dropdown content:** A DaisyUI `menu` inside `dropdown-content`, containing:
- The user's email address, with a `user` Heroicon (outline), as a non-interactive label row.
- "Sign out", with an `arrow-right-on-rectangle` Heroicon (outline), as the existing `button_to session_path, method: :delete` action.

**Placement:** `dropdown-end` so the menu aligns under the avatar without overflowing the right edge of the nav.

**Icons:** Both icons come from the `heroicon` gem already installed and configured (`docs/superpowers/specs/2026-08-16-heroicons-standard-design.md`), using the default `:outline` variant — no new variant overrides needed.

## Out of scope

- No changes to the sign-out behavior itself (still a DELETE to `session_path`).
- No additional dropdown items (e.g. settings, profile) — only what already exists (email, sign out).
