# Standardize on Heroicons for icons

## Problem

The project has no icon library. DaisyUI (the styling library already in use) does not ship icons — its components expect raw SVGs to be supplied. This was an open decision; the project needs one standard so future work doesn't each pick a different approach.

## Design

**Library:** [Heroicons](https://heroicons.com/), via the `heroicon` Ruby gem ([bharget/heroicon](https://github.com/bharget/heroicon)). Renders inline SVG server-side through a view helper — no npm/JS dependency, consistent with how this app already handles Tailwind/DaisyUI (compiled CSS, no JS bundler for styling).

**Install:**
- Add `gem "heroicon"` to the `Gemfile`.
- Run `rails g heroicon:install`, which generates `config/initializers/heroicon.rb`.

**Default variant:** `:outline` (the gem defaults to `:solid`; override in the generated initializer).

**Usage in views:**
```erb
<%= heroicon "check", options: { class: "size-5" } %>
```
Per-icon overrides use `variant: :solid` or `variant: :mini`.

**Documentation:** Add a short "Icons" section to `AGENTS.md` (under "Frontend") stating Heroicons/`heroicon` gem is the standard, the default variant, and the one-line usage example above — so this stops being an open question for future work.

## Out of scope

- No migration of existing markup (nothing in the app currently uses icons).
- No custom wrapper/component around the `heroicon` helper — use it directly.
