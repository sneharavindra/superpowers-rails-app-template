# User Settings and Account Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a User Settings page (edit email address) and an Account Settings page (edit account name), both linked from the nav dropdown.

**Architecture:** Two new singular-resource controllers (`UserSettingsController`, `AccountSettingsController`), each with `edit`/`update` actions following the existing `RegistrationsController` pattern (update, redirect with notice on success, re-render `:edit` with inline errors on failure). Both render inside the `authenticated` layout. Nav dropdown gets two new links.

**Tech Stack:** Rails 8 controllers/views (ERB), DaisyUI form components, `heroicon` gem, Minitest.

## Global Constraints

- User Settings edits only `email_address`; Account Settings edits only `name` (spec: `docs/superpowers/specs/2026-08-16-user-account-settings-design.md`)
- No password change, no slug editing, no roles/authorization layer (none exists yet)
- Both controllers scope to `Current.user` / `Current.user.account` only — never accept an id from params
- Both controllers set `layout "authenticated"`

---

### Task 1: User Settings page

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/user_settings_controller.rb`
- Create: `app/views/user_settings/edit.html.erb`
- Test: `test/controllers/user_settings_controller_test.rb`

**Interfaces:**
- Produces: routes `edit_user_settings_path` (GET), `user_settings_path` (PATCH); controller `UserSettingsController#edit`, `#update`.
- Consumes: `Current.user` (from `app/models/current.rb`).

- [ ] **Step 1: Write the failing tests**

Create `test/controllers/user_settings_controller_test.rb`:

```ruby
require "test_helper"

class UserSettingsControllerTest < ActionDispatch::IntegrationTest
  test "unauthenticated user is redirected to login" do
    get edit_user_settings_url
    assert_redirected_to new_session_url
  end

  test "authenticated user sees their current email in the form" do
    user = users(:one)
    post session_url, params: { email_address: user.email_address, password: "password" }

    get edit_user_settings_url
    assert_response :ok
    assert_select "input[name=?][value=?]", "user[email_address]", user.email_address
  end

  test "updates the email address with valid params" do
    user = users(:one)
    post session_url, params: { email_address: user.email_address, password: "password" }

    patch user_settings_url, params: { user: { email_address: "new-email@example.com" } }
    assert_redirected_to edit_user_settings_url
    assert_equal "new-email@example.com", user.reload.email_address
  end

  test "rejects an invalid email address" do
    user = users(:one)
    post session_url, params: { email_address: user.email_address, password: "password" }

    patch user_settings_url, params: { user: { email_address: "" } }
    assert_response :unprocessable_entity
    assert_not_equal "", user.reload.email_address
  end
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bin/rails test test/controllers/user_settings_controller_test.rb`
Expected: FAIL — route doesn't exist yet (`edit_user_settings_url` undefined).

- [ ] **Step 3: Add the route**

In `config/routes.rb`, add after `resources :passwords, param: :token`:

```ruby
  resource :user_settings, only: %i[edit update]
```

- [ ] **Step 4: Create the controller**

Create `app/controllers/user_settings_controller.rb`:

```ruby
class UserSettingsController < ApplicationController
  layout "authenticated"

  def edit
    @user = Current.user
  end

  def update
    @user = Current.user

    if @user.update(user_settings_params)
      redirect_to edit_user_settings_path, notice: "Settings updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_settings_params
    params.require(:user).permit(:email_address)
  end
end
```

- [ ] **Step 5: Create the view**

Create `app/views/user_settings/edit.html.erb`:

```erb
<div class="mx-auto md:w-2/3 w-full">
  <% if notice = flash[:notice] %>
    <div role="alert" class="alert alert-success mb-5"><%= notice %></div>
  <% end %>

  <% if @user.errors.any? %>
    <div role="alert" class="alert alert-error mb-5">
      <ul>
        <% @user.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <h1 class="font-bold text-4xl mb-6">User settings</h1>

  <%= form_with model: @user, url: user_settings_path, method: :patch, class: "contents" do |form| %>
    <fieldset class="fieldset">
      <legend class="fieldset-legend">Email address</legend>
      <%= form.email_field :email_address, required: true, autocomplete: "email", class: "input w-full" %>
    </fieldset>

    <%= form.submit "Save", class: "btn btn-primary mt-4" %>
  <% end %>
</div>
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `bin/rails test test/controllers/user_settings_controller_test.rb`
Expected: PASS (4 runs, 0 failures)

- [ ] **Step 7: Run the full test suite to check for regressions**

Run: `bin/rails test`
Expected: All tests PASS.

- [ ] **Step 8: Run rubocop**

Run: `bundle exec rubocop app/controllers/user_settings_controller.rb test/controllers/user_settings_controller_test.rb`
Expected: No offenses.

- [ ] **Step 9: Commit**

```bash
git add config/routes.rb app/controllers/user_settings_controller.rb app/views/user_settings/edit.html.erb test/controllers/user_settings_controller_test.rb
git commit -m "Add User Settings page for editing email address"
```

---

### Task 2: Account Settings page

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/account_settings_controller.rb`
- Create: `app/views/account_settings/edit.html.erb`
- Test: `test/controllers/account_settings_controller_test.rb`

**Interfaces:**
- Produces: routes `edit_account_settings_path` (GET), `account_settings_path` (PATCH); controller `AccountSettingsController#edit`, `#update`.
- Consumes: `Current.user.account`.

- [ ] **Step 1: Write the failing tests**

Create `test/controllers/account_settings_controller_test.rb`:

```ruby
require "test_helper"

class AccountSettingsControllerTest < ActionDispatch::IntegrationTest
  test "unauthenticated user is redirected to login" do
    get edit_account_settings_url
    assert_redirected_to new_session_url
  end

  test "authenticated user sees their account's current name in the form" do
    user = users(:one)
    post session_url, params: { email_address: user.email_address, password: "password" }

    get edit_account_settings_url
    assert_response :ok
    assert_select "input[name=?][value=?]", "account[name]", user.account.name
  end

  test "updates the account name with valid params" do
    user = users(:one)
    post session_url, params: { email_address: user.email_address, password: "password" }

    patch account_settings_url, params: { account: { name: "New Org Name" } }
    assert_redirected_to edit_account_settings_url
    assert_equal "New Org Name", user.account.reload.name
  end

  test "rejects a blank account name" do
    user = users(:one)
    post session_url, params: { email_address: user.email_address, password: "password" }

    original_name = user.account.name
    patch account_settings_url, params: { account: { name: "" } }
    assert_response :unprocessable_entity
    assert_equal original_name, user.account.reload.name
  end
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bin/rails test test/controllers/account_settings_controller_test.rb`
Expected: FAIL — route doesn't exist yet.

- [ ] **Step 3: Add the route**

In `config/routes.rb`, add immediately after the `resource :user_settings, only: %i[edit update]` line from Task 1:

```ruby
  resource :account_settings, only: %i[edit update]
```

- [ ] **Step 4: Add a presence validation on Account#name**

The "rejects a blank account name" test requires `Account` to actually reject blank names. Check `app/models/account.rb` first — if it has no validation on `name`, add one:

```ruby
class Account < ApplicationRecord
  has_many :users, dependent: :destroy

  validates :name, presence: true
end
```

If a `name` presence validation already exists, skip this step.

- [ ] **Step 5: Create the controller**

Create `app/controllers/account_settings_controller.rb`:

```ruby
class AccountSettingsController < ApplicationController
  layout "authenticated"

  def edit
    @account = Current.user.account
  end

  def update
    @account = Current.user.account

    if @account.update(account_settings_params)
      redirect_to edit_account_settings_path, notice: "Settings updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def account_settings_params
    params.require(:account).permit(:name)
  end
end
```

- [ ] **Step 6: Create the view**

Create `app/views/account_settings/edit.html.erb`:

```erb
<div class="mx-auto md:w-2/3 w-full">
  <% if notice = flash[:notice] %>
    <div role="alert" class="alert alert-success mb-5"><%= notice %></div>
  <% end %>

  <% if @account.errors.any? %>
    <div role="alert" class="alert alert-error mb-5">
      <ul>
        <% @account.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <h1 class="font-bold text-4xl mb-6">Account settings</h1>

  <%= form_with model: @account, url: account_settings_path, method: :patch, class: "contents" do |form| %>
    <fieldset class="fieldset">
      <legend class="fieldset-legend">Account name</legend>
      <%= form.text_field :name, required: true, class: "input w-full" %>
    </fieldset>

    <%= form.submit "Save", class: "btn btn-primary mt-4" %>
  <% end %>
</div>
```

- [ ] **Step 7: Run the tests to verify they pass**

Run: `bin/rails test test/controllers/account_settings_controller_test.rb`
Expected: PASS (4 runs, 0 failures)

- [ ] **Step 8: Run the full test suite to check for regressions**

Run: `bin/rails test`
Expected: All tests PASS.

- [ ] **Step 9: Run rubocop**

Run: `bundle exec rubocop app/controllers/account_settings_controller.rb app/models/account.rb test/controllers/account_settings_controller_test.rb`
Expected: No offenses.

- [ ] **Step 10: Commit**

```bash
git add config/routes.rb app/controllers/account_settings_controller.rb app/models/account.rb app/views/account_settings/edit.html.erb test/controllers/account_settings_controller_test.rb
git commit -m "Add Account Settings page for editing account name"
```

---

### Task 3: Link both pages from the nav dropdown

**Files:**
- Modify: `app/views/layouts/authenticated.html.erb`
- Modify: `test/controllers/dashboard_controller_test.rb`

**Interfaces:**
- Consumes: `edit_user_settings_path`, `edit_account_settings_path` (from Tasks 1-2), `heroicon` helper.

- [ ] **Step 1: Write the failing test**

In `test/controllers/dashboard_controller_test.rb`, update the `"authenticated user sees nav with brand and a user dropdown"` test — add these two assertions inside the existing `assert_select "details.dropdown" do ... end` block, right after the `assert_select "summary.avatar"` line:

```ruby
        assert_select "a[href=?]", edit_user_settings_path, text: /User Settings/ do
          assert_select "svg"
        end
        assert_select "a[href=?]", edit_account_settings_path, text: /Account Settings/ do
          assert_select "svg"
        end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bin/rails test test/controllers/dashboard_controller_test.rb`
Expected: FAIL — the two links don't exist yet.

- [ ] **Step 3: Add the links to the dropdown**

In `app/views/layouts/authenticated.html.erb`, inside the `<ul class="dropdown-content menu ...">`, add two new `<li>` elements between the email `<li class="menu-title">` block and the "Sign out" `<li>`:

```erb
          <li>
            <%= link_to edit_user_settings_path, class: "flex items-center gap-2" do %>
              <%= heroicon "cog-6-tooth", options: { class: "size-4" } %>
              User Settings
            <% end %>
          </li>
          <li>
            <%= link_to edit_account_settings_path, class: "flex items-center gap-2" do %>
              <%= heroicon "building-office", options: { class: "size-4" } %>
              Account Settings
            <% end %>
          </li>
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bin/rails test test/controllers/dashboard_controller_test.rb`
Expected: PASS

- [ ] **Step 5: Run the full test suite to check for regressions**

Run: `bin/rails test`
Expected: All tests PASS.

- [ ] **Step 6: Run rubocop**

Run: `bundle exec rubocop test/controllers/dashboard_controller_test.rb`
Expected: No offenses.

- [ ] **Step 7: Manual visual check**

Using an authenticated curl session (as in prior tasks): confirm `GET /dashboard` HTML shows both new links in the dropdown markup with their icons; confirm `GET /user_settings/edit` and `GET /account_settings/edit` both return 200 and render inside the authenticated layout (nav + footer present); submit each form with a valid change via curl and confirm the underlying record updates and the response redirects.

- [ ] **Step 8: Commit**

```bash
git add app/views/layouts/authenticated.html.erb test/controllers/dashboard_controller_test.rb docs/superpowers/plans/2026-08-16-user-account-settings.md
git commit -m "Link User Settings and Account Settings from the nav dropdown"
```
