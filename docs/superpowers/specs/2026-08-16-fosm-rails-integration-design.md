# FOSM-Rails Integration Design

**Date:** 2026-08-16
**Status:** Approved

## Goal

Install and configure the `fosm-rails` gem (gem-only; no FOSM apps generated yet). Wire up the engine to TalkyForm's custom auth. Add a `superadmin` flag to `User` to gate admin access. Document the FOSM philosophy in `AGENTS.md` as architectural guidance for AI agents.

## Scope

- Add `fosm-rails` to `Gemfile` and run its migrations
- Add `superadmin` boolean to `users`
- Configure `config/initializers/fosm.rb` adapted to `Current.user`
- Mount engine in `config/routes.rb`
- Add FOSM philosophy section to `AGENTS.md`

Out of scope: generating FOSM app models, controllers, views, or agents.

## Gem & Migrations

Add to `Gemfile`:
```ruby
gem "fosm-rails"
```

Run:
```bash
bundle install
rails fosm:install:migrations
rails db:migrate
```

FOSM creates: `fosm_transition_logs`, `fosm_role_assignments`, `fosm_webhook_subscriptions`, `fosm_access_events`.

Separate migration: add `superadmin: boolean, default: false, null: false` to `users`.

## Engine Configuration

`config/initializers/fosm.rb`:

```ruby
Fosm.configure do |config|
  config.base_controller        = "ApplicationController"
  config.current_user_method    = -> { Current.user }
  config.admin_authorize        = -> { redirect_to root_path unless Current.user&.superadmin? }
  config.app_authorize          = ->(_level) {}
  config.admin_layout           = "application"
  config.app_layout             = "application"
  config.transition_log_strategy = :async
end
```

**Why `app_authorize` is a no-op:** `ApplicationController` already enforces `require_authentication` globally via `before_action`. FOSM controllers inherit this because `base_controller = "ApplicationController"`. No duplicate auth logic needed.

**Why `:async` for `transition_log_strategy`:** TalkyForm uses Solid Queue inside Puma. Async log writes keep state transitions fast without sacrificing auditability. Use `:sync` only if strict consistency is required for a specific FOSM app.

## Routes

```ruby
mount Fosm::Engine => "/fosm"
draw :fosm
```

The `draw :fosm` line loads `config/routes/fosm.rb`, which is auto-created and updated by FOSM generators.

## User Model

Add `superadmin` boolean:

```ruby
add_column :users, :superadmin, :boolean, default: false, null: false
```

No model logic needed beyond the column — `Current.user&.superadmin?` is the only call site.

## AGENTS.md Philosophy Section

New section: `## Business Process Management with FOSM`

Covers:
1. **When to use FOSM** — any model whose allowed operations depend on its current state
2. **The four primitives** — states, events, guards, side effects
3. **Bounded autonomy** — AI agents are constrained by the machine; they cannot bypass guards or invent transitions
4. **When NOT to use FOSM** — stateless data, simple boolean flags, UI-only toggles, objects with no lifecycle
5. **Architecture rule** — FOSM models live under `app/models/fosm/`; one lifecycle per model; no business logic outside the lifecycle block
