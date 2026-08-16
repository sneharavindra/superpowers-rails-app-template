# FOSM-Rails Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install and configure `fosm-rails`, gate admin access behind a `superadmin` flag, and document the FOSM philosophy in `AGENTS.md`.

**Architecture:** `fosm-rails` is mounted as a Rails engine at `/fosm`. It inherits `ApplicationController` as its base, which means TalkyForm's `require_authentication` concern fires automatically. The engine is configured to read `Current.user` (not a `current_user` helper method) and to restrict `/fosm/admin` to users with `superadmin: true`.

**Tech Stack:** Rails 8.1, fosm-rails gem, SQLite, Minitest, `ActiveSupport::CurrentAttributes` (`Current.user`)

## Global Constraints

- Database: SQLite only — no Postgres-specific syntax
- Auth: Custom Rails 8 concern via `Current.user`; no Devise, no `current_user` helper method
- No FOSM apps generated in this plan — engine install only
- `transition_log_strategy: :async` — uses Solid Queue (already running inside Puma)
- Tests: Minitest, run with `bin/rails test`

---

### Task 1: Add gem and run FOSM migrations

**Files:**
- Modify: `Gemfile`
- Auto-created by generator: `db/migrate/*_create_fosm_*.rb` and `config/routes/fosm.rb`

**Interfaces:**
- Produces: FOSM tables in the database; `config/routes/fosm.rb` file for Task 4 to reference

- [ ] **Step 1: Add the gem**

In `Gemfile`, after the `bcrypt` line, add:

```ruby
gem "fosm-rails"
```

- [ ] **Step 2: Install**

```bash
bundle install
```

Expected: fosm-rails and its dependency `gemlings` install without errors.

- [ ] **Step 3: Install FOSM migrations**

```bash
bin/rails fosm:install:migrations
```

Expected: Several migration files copied to `db/migrate/` — at minimum `create_fosm_transition_logs`, `create_fosm_role_assignments`, `create_fosm_webhook_subscriptions`, `create_fosm_access_events`.

- [ ] **Step 4: Run migrations**

```bash
bin/rails db:migrate
```

Expected: All FOSM migrations run without errors.

- [ ] **Step 5: Verify tables exist**

```bash
bin/rails runner "puts ActiveRecord::Base.connection.tables.select { |t| t.start_with?('fosm') }.sort"
```

Expected output includes: `fosm_access_events`, `fosm_role_assignments`, `fosm_transition_logs`, `fosm_webhook_subscriptions`.

- [ ] **Step 6: Commit**

```bash
git add Gemfile Gemfile.lock db/migrate db/schema.rb
git commit -m "Add fosm-rails gem and run engine migrations"
```

---

### Task 2: Add superadmin boolean to users

**Files:**
- Create: `db/migrate/TIMESTAMP_add_superadmin_to_users.rb`
- Modify: `db/schema.rb` (auto-updated by migrate)
- Test: `test/models/user_test.rb`

**Interfaces:**
- Produces: `User#superadmin` boolean column, default `false` — consumed by Task 3's `admin_authorize` lambda

- [ ] **Step 1: Write a failing test**

Create `test/models/user_test.rb` (or append if it exists):

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "superadmin defaults to false" do
    account = accounts(:one)
    user = User.create!(
      account: account,
      email_address: "test_superadmin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert_equal false, user.superadmin
  end

  test "superadmin can be set to true" do
    account = accounts(:one)
    user = User.create!(
      account: account,
      email_address: "admin_superadmin@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true
    )
    assert user.superadmin
  end
end
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
bin/rails test test/models/user_test.rb
```

Expected: Error — `unknown attribute 'superadmin'`

- [ ] **Step 3: Generate the migration**

```bash
bin/rails generate migration AddSuperadminToUsers superadmin:boolean
```

- [ ] **Step 4: Edit the migration to add default and null constraint**

Open the generated file in `db/migrate/` and ensure it reads:

```ruby
class AddSuperadminToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :superadmin, :boolean, default: false, null: false
  end
end
```

- [ ] **Step 5: Run the migration**

```bash
bin/rails db:migrate
```

- [ ] **Step 6: Run the test to confirm it passes**

```bash
bin/rails test test/models/user_test.rb
```

Expected: 2 tests, 0 failures.

- [ ] **Step 7: Commit**

```bash
git add db/migrate db/schema.rb test/models/user_test.rb
git commit -m "Add superadmin boolean to users (default false)"
```

---

### Task 3: Configure FOSM initializer

**Files:**
- Create: `config/initializers/fosm.rb`

**Interfaces:**
- Consumes: `Current.user` from `app/models/current.rb`; `User#superadmin` from Task 2
- Produces: FOSM engine configured with TalkyForm auth

- [ ] **Step 1: Create the initializer**

Create `config/initializers/fosm.rb`:

```ruby
Fosm.configure do |config|
  # FOSM controllers inherit ApplicationController, which already enforces
  # require_authentication globally — no duplicate auth needed here.
  config.base_controller = "ApplicationController"

  # TalkyForm uses CurrentAttributes, not a current_user helper method.
  config.current_user_method = -> { Current.user }

  # Only superadmins can access /fosm/admin.
  config.admin_authorize = -> { redirect_to root_path unless Current.user&.superadmin? }

  # app_authorize is a no-op: ApplicationController already enforces auth.
  config.app_authorize = ->(_level) {}

  config.admin_layout = "application"
  config.app_layout   = "application"

  # :async uses Solid Queue (already running inside Puma) for non-blocking log writes.
  config.transition_log_strategy = :async
end
```

- [ ] **Step 2: Verify the app boots**

```bash
bin/rails runner "puts Fosm.configuration.base_controller"
```

Expected: `ApplicationController`

- [ ] **Step 3: Commit**

```bash
git add config/initializers/fosm.rb
git commit -m "Configure FOSM engine with TalkyForm auth (Current.user, superadmin gate)"
```

---

### Task 4: Mount FOSM engine in routes

**Files:**
- Modify: `config/routes.rb`
- Pre-exists (from Task 1): `config/routes/fosm.rb`

**Interfaces:**
- Consumes: `config/routes/fosm.rb` (auto-created by `fosm:install:migrations`)
- Produces: `/fosm` and `/fosm/admin` routes

- [ ] **Step 1: Write a failing integration test**

Create `test/integration/fosm_admin_access_test.rb`:

```ruby
require "test_helper"

class FosmAdminAccessTest < ActionDispatch::IntegrationTest
  test "unauthenticated user cannot reach fosm admin" do
    get "/fosm/admin"
    assert_redirected_to new_session_url
  end

  test "authenticated non-superadmin is redirected to root" do
    user = users(:one)
    post session_url, params: { email_address: user.email_address, password: "password" }

    get "/fosm/admin"
    assert_redirected_to root_url
  end

  test "superadmin can access fosm admin" do
    user = users(:one)
    user.update!(superadmin: true)
    post session_url, params: { email_address: user.email_address, password: "password" }

    get "/fosm/admin"
    assert_response :ok
  end
end
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
bin/rails test test/integration/fosm_admin_access_test.rb
```

Expected: Routing error — no route matches `/fosm/admin`

- [ ] **Step 3: Mount the engine**

In `config/routes.rb`, add before the existing routes:

```ruby
mount Fosm::Engine => "/fosm"
draw :fosm
```

The full file should look like:

```ruby
Rails.application.routes.draw do
  mount Fosm::Engine => "/fosm"
  draw :fosm

  root "home#index"

  get  "signup", to: "registrations#new",    as: :new_registration
  post "signup", to: "registrations#create",  as: :registrations

  get "dashboard", to: "dashboard#index", as: :dashboard

  resource :session
  resources :passwords, param: :token

  get "up" => "rails/health#show", as: :rails_health_check
end
```

- [ ] **Step 4: Verify routes**

```bash
bin/rails routes | grep fosm
```

Expected: Several `/fosm/...` routes including `/fosm/admin`.

- [ ] **Step 5: Run the integration test**

```bash
bin/rails test test/integration/fosm_admin_access_test.rb
```

Expected: 3 tests, 0 failures.

- [ ] **Step 6: Run the full test suite**

```bash
bin/rails test
```

Expected: All tests pass, 0 failures.

- [ ] **Step 7: Commit**

```bash
git add config/routes.rb config/routes/fosm.rb test/integration/fosm_admin_access_test.rb
git commit -m "Mount FOSM engine at /fosm; add admin access integration tests"
```

---

### Task 5: Document FOSM philosophy in AGENTS.md

**Files:**
- Modify: `AGENTS.md`

**Interfaces:**
- Produces: `## Business Process Management with FOSM` section that AI agents read as architectural guidance

- [ ] **Step 1: Add the FOSM philosophy section to AGENTS.md**

Append the following section to `AGENTS.md` (after the existing `### Skills` section):

```markdown
## Business Process Management with FOSM

TalkyForm uses `fosm-rails` to model business objects that have a **lifecycle** — objects whose permitted operations depend on their current state. The engine is mounted at `/fosm`. FOSM apps live under `app/models/fosm/`, `app/controllers/fosm/`, `app/views/fosm/`, and `app/agents/fosm/`.

### When to use FOSM

Use FOSM for any model where the answer to "what can I do with this?" depends on where it currently is in its process. Examples: a form submission that moves from `draft → submitted → reviewed → accepted/rejected`, or a subscription that moves from `trial → active → cancelled`.

Do not use FOSM for:
- Stateless data (lookup tables, pure reference data)
- Simple boolean flags (`published: true/false`) with no lifecycle consequence
- UI-only toggles with no business rules attached
- Models where every operation is always available regardless of state

### The four primitives

Every FOSM lifecycle is built from exactly four building blocks:

| Primitive | Purpose | Rule |
|-----------|---------|------|
| `state` | A named position in the lifecycle | Exactly one `initial: true`; terminal states have no outgoing events |
| `event` | A named transition between states | Declares `from:` and `to:`; multiple `from:` states allowed |
| `guard` | A pure predicate that blocks an event | Returns `true` (allow) or `false` (block); no side effects inside guards |
| `side_effect` | Work that runs after the transition persists | Runs inside the same DB transaction; use for emails, webhooks, cascades |

### Bounded autonomy for AI agents

Every FOSM model automatically exposes a Gemlings AI agent. The agent is **bounded by the machine**: it can only fire events that exist in the lifecycle definition. It cannot bypass guards. It cannot invent transitions. Every action is written to the immutable `fosm_transition_logs` table.

This is the core design principle: the lifecycle definition is the contract between the domain and any actor — human UI, background job, or AI agent. The machine enforces it. The agent operates within it.

When writing FOSM lifecycle definitions, design for the agent as a first-class actor: name events clearly (`approve`, not `set_state_to_approved`), write guards that return meaningful error context, and keep side effects focused on one concern each.

### Architecture rules for FOSM models

- One lifecycle per model. Do not split lifecycle logic across concerns or callbacks.
- No business logic outside the `lifecycle` block. Guards and side effects own the rules.
- State is a string column named `state` on the model. Never read or write it directly — use events.
- Fire events with `record.event_name!(actor: current_user)` from controllers. Never set `record.state =` anywhere.
- RBAC: if the lifecycle has an `access` block, use `fosm_authorize!` in the controller. If not, the object is open-by-default for all authenticated actors.
- The `fosm_transition_logs` table is immutable. Never delete or update rows in it.
```

- [ ] **Step 2: Verify the section renders correctly**

```bash
grep -n "Business Process Management with FOSM" AGENTS.md
```

Expected: One match at the correct line.

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "Document FOSM philosophy in AGENTS.md as architectural guidance"
```
