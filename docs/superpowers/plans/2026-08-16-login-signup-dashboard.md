# Login / Signup Entry Point & Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Rails welcome page with an auth-aware home redirect, add account+user sign-up, and a minimal authenticated dashboard.

**Architecture:** `HomeController#index` (no view) checks `authenticated?` and redirects to dashboard or login. `RegistrationsController` creates an `Account` and `User` in a transaction, then starts a session. `DashboardController#index` is the authenticated landing page.

**Tech Stack:** Rails 8.1, Minitest, Hotwire/Turbo, Tailwind CSS + DaisyUI, custom auth concern (`Authentication`)

## Global Constraints

- Custom auth — no Devise. Use `allow_unauthenticated_access` to opt out of `require_authentication`.
- Start sessions via `start_new_session_for(user)` from `Authentication` concern.
- `User` belongs to `Account` — `account_id NOT NULL`. Always create both in a transaction.
- Account name: `"#{first_name}'s Org"` — first_name is everything before the first space in the submitted name (fallback: full name).
- SQLite only — no Postgres-specific SQL.
- Minitest with fixtures — tests in `test/` mirroring `app/`.
- Run tests with `bin/rails test`.

---

### Task 1: Routes

**Files:**
- Modify: `config/routes.rb`

**Interfaces:**
- Produces: named routes `root_path`, `new_registration_path`, `registrations_path` (POST), `dashboard_path`

- [ ] **Step 1: Add routes**

Edit `config/routes.rb` to add:

```ruby
Rails.application.routes.draw do
  root "home#index"

  get  "signup", to: "registrations#new",    as: :new_registration
  post "signup", to: "registrations#create",  as: :registrations

  get "dashboard", to: "dashboard#index", as: :dashboard

  resource :session
  resources :passwords, param: :token

  get "up" => "rails/health#show", as: :rails_health_check
end
```

- [ ] **Step 2: Verify routes load**

```bash
bin/rails routes | grep -E "root|signup|dashboard"
```

Expected output includes lines for `root`, `new_registration`, `registrations`, `dashboard`.

- [ ] **Step 3: Commit**

```bash
git add config/routes.rb
git commit -m "Add routes for home redirect, signup, and dashboard"
```

---

### Task 2: HomeController

**Files:**
- Create: `app/controllers/home_controller.rb`
- Test: `test/controllers/home_controller_test.rb`

**Interfaces:**
- Consumes: `authenticated?` helper from `Authentication` concern; `dashboard_path`, `new_session_path` named routes
- Produces: `GET /` — redirects to dashboard (authenticated) or login (unauthenticated)

- [ ] **Step 1: Write failing tests**

Create `test/controllers/home_controller_test.rb`:

```ruby
require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "unauthenticated user is redirected to login" do
    get root_url
    assert_redirected_to new_session_url
  end

  test "authenticated user is redirected to dashboard" do
    user = users(:one)
    post session_url, params: { email_address: user.email_address, password: "password" }

    get root_url
    assert_redirected_to dashboard_url
  end
end
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
bin/rails test test/controllers/home_controller_test.rb
```

Expected: errors about missing `HomeController`.

- [ ] **Step 3: Create HomeController**

Create `app/controllers/home_controller.rb`:

```ruby
class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    if authenticated?
      redirect_to dashboard_path
    else
      redirect_to new_session_path
    end
  end
end
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
bin/rails test test/controllers/home_controller_test.rb
```

Expected: 2 tests, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/home_controller.rb test/controllers/home_controller_test.rb
git commit -m "Add HomeController with auth-aware redirect"
```

---

### Task 3: DashboardController and view

**Files:**
- Create: `app/controllers/dashboard_controller.rb`
- Create: `app/views/dashboard/index.html.erb`
- Test: `test/controllers/dashboard_controller_test.rb`

**Interfaces:**
- Consumes: `require_authentication` (default, from `Authentication` concern); `Current.user`
- Produces: `GET /dashboard` — renders placeholder for authenticated users

- [ ] **Step 1: Check what fixture users look like**

```bash
cat test/fixtures/users.yml
```

Note the fixture name and email/password used in tests.

- [ ] **Step 2: Write failing tests**

Create `test/controllers/dashboard_controller_test.rb`:

```ruby
require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "unauthenticated user is redirected to login" do
    get dashboard_url
    assert_redirected_to new_session_url
  end

  test "authenticated user sees dashboard" do
    user = users(:one)
    post session_url, params: { email_address: user.email_address, password: "password" }

    get dashboard_url
    assert_response :ok
    assert_select "h1", text: /Welcome/
  end
end
```

- [ ] **Step 3: Run tests to confirm they fail**

```bash
bin/rails test test/controllers/dashboard_controller_test.rb
```

Expected: errors about missing `DashboardController`.

- [ ] **Step 4: Create DashboardController**

Create `app/controllers/dashboard_controller.rb`:

```ruby
class DashboardController < ApplicationController
  def index
  end
end
```

- [ ] **Step 5: Create dashboard view**

Create `app/views/dashboard/index.html.erb`:

```erb
<div class="flex flex-col items-center justify-center min-h-64">
  <h1 class="text-3xl font-bold text-base-content">
    Welcome, <%= Current.user.email_address.split("@").first.capitalize %>
  </h1>
  <p class="mt-3 text-base-content/60">Your dashboard is on its way.</p>
</div>
```

> Note: `Current.user` is set by the `Authentication` concern via `resume_session`. We derive a display name from the email address since the `User` model has no `name` column. This is a placeholder — the welcome message will improve once a name field exists.

- [ ] **Step 6: Run tests to confirm they pass**

```bash
bin/rails test test/controllers/dashboard_controller_test.rb
```

Expected: 2 tests, 0 failures.

- [ ] **Step 7: Commit**

```bash
git add app/controllers/dashboard_controller.rb app/views/dashboard/index.html.erb test/controllers/dashboard_controller_test.rb
git commit -m "Add DashboardController with minimal placeholder view"
```

---

### Task 4: RegistrationsController and sign-up view

**Files:**
- Create: `app/controllers/registrations_controller.rb`
- Create: `app/views/registrations/new.html.erb`
- Test: `test/controllers/registrations_controller_test.rb`

**Interfaces:**
- Consumes: `Account` model, `User` model, `start_new_session_for(user)` from `Authentication` concern; `dashboard_path`, `new_session_path`
- Produces: `GET /signup` — sign-up form; `POST /signup` — creates Account + User, starts session, redirects to dashboard

- [ ] **Step 1: Write failing tests**

Create `test/controllers/registrations_controller_test.rb`:

```ruby
require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "renders sign-up form" do
    get new_registration_url
    assert_response :ok
    assert_select "form"
  end

  test "creates account and user then redirects to dashboard" do
    assert_difference([ "Account.count", "User.count" ], 1) do
      post registrations_url, params: {
        name: "Sneha Ravindra",
        email_address: "sneha@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    end

    assert_redirected_to dashboard_url
    assert_equal "Sneha's Org", Account.last.name
  end

  test "re-renders form on invalid submission" do
    assert_no_difference("User.count") do
      post registrations_url, params: {
        name: "Sneha Ravindra",
        email_address: "",
        password: "password123",
        password_confirmation: "password123"
      }
    end

    assert_response :unprocessable_entity
  end

  test "first name fallback when name has no spaces" do
    post registrations_url, params: {
      name: "Sneha",
      email_address: "sneha2@example.com",
      password: "password123",
      password_confirmation: "password123"
    }

    assert_equal "Sneha's Org", Account.last.name
  end
end
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
bin/rails test test/controllers/registrations_controller_test.rb
```

Expected: errors about missing `RegistrationsController`.

- [ ] **Step 3: Create RegistrationsController**

Create `app/controllers/registrations_controller.rb`:

```ruby
class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    @user = User.new
  end

  def create
    first_name = params[:name].to_s.split(" ", 2).first.presence || params[:name].to_s

    ActiveRecord::Base.transaction do
      @account = Account.create!(name: "#{first_name}'s Org")
      @user = User.create!(
        account: @account,
        email_address: params[:email_address],
        password: params[:password],
        password_confirmation: params[:password_confirmation]
      )
    end

    start_new_session_for @user
    redirect_to dashboard_path
  rescue ActiveRecord::RecordInvalid => e
    @user ||= User.new(email_address: params[:email_address])
    @user.errors.add(:base, e.message) if @user.errors.empty?
    render :new, status: :unprocessable_entity
  end
end
```

- [ ] **Step 4: Create sign-up view**

Create `app/views/registrations/new.html.erb`:

```erb
<div class="mx-auto md:w-2/3 w-full">
  <% if @user.errors.any? %>
    <div class="alert alert-error mb-5">
      <ul>
        <% @user.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <h1 class="font-bold text-4xl mb-6">Create your account</h1>

  <%= form_with url: registrations_path, class: "contents" do |form| %>
    <div class="my-5">
      <%= form.label :name, "Full name", class: "block text-sm font-medium text-gray-700" %>
      <%= form.text_field :name, required: true, autofocus: true, autocomplete: "name",
            placeholder: "Jane Smith",
            class: "block shadow-sm rounded-md border border-gray-400 focus:outline-blue-600 px-3 py-2 mt-2 w-full" %>
    </div>

    <div class="my-5">
      <%= form.label :email_address, "Email address", class: "block text-sm font-medium text-gray-700" %>
      <%= form.email_field :email_address, required: true, autocomplete: "email",
            placeholder: "you@example.com",
            class: "block shadow-sm rounded-md border border-gray-400 focus:outline-blue-600 px-3 py-2 mt-2 w-full" %>
    </div>

    <div class="my-5">
      <%= form.label :password, "Password", class: "block text-sm font-medium text-gray-700" %>
      <%= form.password_field :password, required: true, autocomplete: "new-password",
            maxlength: 72,
            class: "block shadow-sm rounded-md border border-gray-400 focus:outline-blue-600 px-3 py-2 mt-2 w-full" %>
    </div>

    <div class="my-5">
      <%= form.label :password_confirmation, "Confirm password", class: "block text-sm font-medium text-gray-700" %>
      <%= form.password_field :password_confirmation, required: true, autocomplete: "new-password",
            maxlength: 72,
            class: "block shadow-sm rounded-md border border-gray-400 focus:outline-blue-600 px-3 py-2 mt-2 w-full" %>
    </div>

    <div class="col-span-6 sm:flex sm:items-center sm:gap-4">
      <%= form.submit "Create account",
            class: "w-full sm:w-auto text-center rounded-md px-3.5 py-2.5 bg-blue-600 hover:bg-blue-500 text-white inline-block font-medium cursor-pointer" %>

      <div class="mt-4 text-sm text-gray-500 sm:mt-0">
        Already have an account?
        <%= link_to "Sign in", new_session_path, class: "text-gray-700 underline hover:no-underline" %>
      </div>
    </div>
  <% end %>
</div>
```

- [ ] **Step 5: Run tests to confirm they pass**

```bash
bin/rails test test/controllers/registrations_controller_test.rb
```

Expected: 4 tests, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/registrations_controller.rb app/views/registrations/new.html.erb test/controllers/registrations_controller_test.rb
git commit -m "Add RegistrationsController: account+user creation with session start"
```

---

### Task 5: Update login view with sign-up link

**Files:**
- Modify: `app/views/sessions/new.html.erb`

**Interfaces:**
- Consumes: `new_registration_path` named route (from Task 1)
- Produces: sign-in page with "Don't have an account? Sign up" link

- [ ] **Step 1: Add sign-up link to sessions/new.html.erb**

In `app/views/sessions/new.html.erb`, add after the closing `<% end %>` of the form:

```erb
<div class="mt-6 text-sm text-gray-500">
  Don't have an account?
  <%= link_to "Sign up", new_registration_path, class: "text-gray-700 underline hover:no-underline" %>
</div>
```

- [ ] **Step 2: Run full test suite**

```bash
bin/rails test
```

Expected: all tests pass, 0 failures.

- [ ] **Step 3: Commit**

```bash
git add app/views/sessions/new.html.erb
git commit -m "Add signup link to login page"
```
