# Authenticated layout: top nav + footer

## Problem

Authenticated pages (currently just the dashboard) have no navigation chrome — no way to sign out, no branding, no footer. Unauthenticated pages (sign-in, signup, forgot password) should stay bare as they are today.

## Design

**Scope:** Authenticated pages only. Sign-in, signup, and password-reset pages are unchanged.

**Shared head partial:** Extract the `<head>` contents of `app/views/layouts/application.html.erb` (title, meta tags, CSRF/CSP tags, `yield :head`, favicons, stylesheet/importmap tags) into `app/views/layouts/_head.html.erb`. Both layouts render this partial, so head content isn't duplicated between them.

**New layout — `app/views/layouts/authenticated.html.erb`:**
- Renders the shared head partial.
- Top nav:
  - Left: brand text "Sneha's App", linking to `dashboard_path`.
  - Right: current user's email address, plus a "Sign out" button (`button_to session_path, method: :delete`).
- `yield` for page content (same as today).
- Footer, centered:
  - "© `<%= Date.current.year %>` " followed by "Sneha's App" as a link to `https://github.com/sneharavindra/superpowers-rails-app-template`, opening in a new tab (`target="_blank" rel="noopener noreferrer"`).

**`application.html.erb`:** Unchanged in body behavior — just switches to rendering the shared `_head` partial instead of inlining head markup. Still used as-is by sign-in/signup/password-reset pages.

**Wiring:** `DashboardController` adds `layout "authenticated"`. Any future authenticated controller opts in the same way. `ApplicationController`'s default layout (`application`) is untouched, so unauthenticated controllers require no changes.

**Styling:** Existing Tailwind + DaisyUI utility classes only, matching the current visual style (no new components or gems).

## Out of scope

- No nav links beyond brand + sign out (no other authenticated pages exist yet to link to).
- No footer links beyond the GitHub link (no privacy/terms pages exist yet).
- No responsive/mobile nav menu — single-row nav is enough for the current content.
