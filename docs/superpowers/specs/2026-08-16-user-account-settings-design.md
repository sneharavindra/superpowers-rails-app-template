# User Settings and Account Settings pages

## Problem

There's no way for a signed-in user to change their own email address or their account's name. Add two simple settings pages, linked from the existing nav dropdown.

## Design

**Scope:** User Settings edits `User#email_address`. Account Settings edits `Account#name`. No password change, no slug editing, no roles/permissions system (none exists yet — see AGENTS.md's multi-tenancy note: "the tenant routing shape is not yet implemented").

**Routes** (`config/routes.rb`):
```ruby
resource :user_settings, only: %i[edit update]
resource :account_settings, only: %i[edit update]
```

**Controllers:**
- `UserSettingsController` — `edit` sets `@user = Current.user`; `update` calls `Current.user.update(user_settings_params)` with `params.require(:user).permit(:email_address)`. On success, redirect to `edit_user_settings_path` with a flash notice; on failure, re-render `:edit` (422) with the invalid `@user` so errors show inline. Mirrors the existing pattern in `RegistrationsController`.
- `AccountSettingsController` — same shape, scoped to `Current.user.account` (never accepts an account id from params, so there's no cross-tenant access risk even without a policy layer).

**Authorization:** Any signed-in user can edit their own user settings and their own account's settings — matches today's open-by-default model (no roles exist on `User` yet). No Pundit/`authorize` calls, consistent with the rest of this codebase (flagged as a standing conflict with `rails-controller-conventions`, not newly introduced here).

**Views:** `app/views/user_settings/edit.html.erb` and `app/views/account_settings/edit.html.erb`, plain `form_with` forms using DaisyUI `fieldset`/`label`/`input`/`btn` classes, matching the existing sign-in page's visual style. Both render inside the authenticated layout (inherited by default — no `layout` override needed since `UserSettingsController`/`AccountSettingsController` extend `ApplicationController`, and only `DashboardController` currently sets `layout "authenticated"`; these two new controllers get the same `layout "authenticated"` declaration).

**Nav integration:** Add two `<li>` items to the existing user dropdown menu in `app/views/layouts/authenticated.html.erb` (the `ul.dropdown-content.menu`), above "Sign out":
- "User Settings" → `edit_user_settings_path`, `cog-6-tooth` icon
- "Account Settings" → `edit_account_settings_path`, `building-office` icon

## Out of scope

- No password change UI.
- No account slug editing.
- No roles/permissions/ownership model — this is deferred until the app actually needs it (per AGENTS.md's multi-tenancy foundation note).
- No email change confirmation flow (e.g. re-verify via email) — direct update, matching the app's current lack of email verification anywhere else.
