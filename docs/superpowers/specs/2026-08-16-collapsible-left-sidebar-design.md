# Collapsible left sidebar in the authenticated layout

## Problem

The authenticated layout (`app/views/layouts/authenticated.html.erb`) currently has a top nav and a full-width `main`. The user wants a left sidebar added, visible next to `main`, collapsible on small screens.

## Design

**Scope:** Authenticated layout only. `application.html.erb` (sign-in/signup/password pages) is unchanged.

**Structure:** DaisyUI's `drawer` component wraps everything below the existing top nav:
- `drawer-content` holds the existing `main` (unchanged content/classes).
- `drawer-side` holds a `menu` sidebar with a single "Dashboard" link (using a `home` Heroicon), styled as the active item since it's currently the only authenticated page.
- The footer stays outside the drawer, full-width, unchanged from today.

**Responsive behavior:** `lg:drawer-open` keeps the sidebar permanently visible (no toggle, no overlay) on large screens. On small screens, it's hidden behind the drawer's built-in checkbox toggle (`drawer-toggle` input + `drawer-overlay` label) — pure CSS, no JS/Stimulus.

**Toggle button:** A hamburger button (`bars-3` Heroicon) is added to the top nav, before the brand link, visible only on small screens (`lg:hidden`), pointing at the drawer's toggle checkbox via `<label for="...">`.

## Out of scope

- No additional sidebar links/sections beyond "Dashboard" (no other authenticated pages exist yet).
- No collapsed-to-icons-only state on desktop — sidebar is either fully visible (large screens) or hidden (small screens, until toggled).
