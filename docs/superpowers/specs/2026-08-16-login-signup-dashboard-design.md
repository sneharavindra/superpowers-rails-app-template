# Login / Signup Entry Point & Dashboard

**Date:** 2026-08-16
**Status:** Approved

## Goal

Replace the default Rails welcome page at `/` with an auth-aware home redirect, add a sign-up flow that creates an Account and User together, and provide a minimal dashboard as the authenticated landing page.

## Routing

```ruby
root "home#index"
get  "signup", to: "registrations#new",  as: :new_registration
post "signup", to: "registrations#create"
get  "dashboard", to: "dashboard#index", as: :dashboard
```

## Controllers

### HomeController

- Single `index` action, no view.
- `allow_unauthenticated_access`.
- Checks `authenticated?`: redirects to `dashboard_path` if true, `new_session_path` if false.

### RegistrationsController

- Actions: `new`, `create`.
- `allow_unauthenticated_access`.
- `create` flow:
  1. Split `params[:name]` on first space to derive `first_name` (fallback: full name if no space).
  2. Wrap in `ActiveRecord::Base.transaction`:
     - Create `Account` with `name: "#{first_name}'s Org"`.
     - Create `User` with `account_id`, `email_address`, `password`, `password_confirmation`.
  3. On success: call `start_new_session_for(user)`, redirect to `dashboard_path`.
  4. On failure: rollback, `render :new, status: :unprocessable_entity` with model errors.

### DashboardController

- Single `index` action.
- Requires authentication (default — no `allow_unauthenticated_access`).

## Views

### `registrations/new.html.erb`

Form fields:
- `name` (full name, single field)
- `email_address`
- `password`
- `password_confirmation`

Inline error display from `@user.errors`. Link to sign-in (`new_session_path`) at the bottom.

### `sessions/new.html.erb` (existing, minor addition)

Add a "Don't have an account? Sign up" link to `new_registration_path` below the existing form.

### `dashboard/index.html.erb`

Minimal placeholder:
- Heading: "Welcome, {Current.user first name}"
- Subline: "Your dashboard is on its way."

## Data & Validation

- `has_secure_password` on `User` handles password presence and confirmation.
- DB unique index on `email_address` handles uniqueness; rescue `ActiveRecord::RecordNotUnique` not needed — AR validates uniqueness via the index and surfaces a model error.
- No new model validations required.
- Account name derived server-side; not exposed as a user-editable field on the sign-up form.

## Out of Scope

- Navigation / app shell
- Account settings
- Invite-only or multi-user account flows
- Email verification
