# Authenticated Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give authenticated pages (starting with the dashboard) a shared layout with a top nav (brand + sign out) and a footer (copyright + GitHub link), while leaving unauthenticated pages (sign-in, signup, password reset) untouched.

**Architecture:** Extract the existing `<head>` markup from `app/views/layouts/application.html.erb` into a shared partial `app/views/layouts/_head.html.erb`. Add a new `app/views/layouts/authenticated.html.erb` that renders that partial plus a nav/footer around `yield`. `DashboardController` opts into the new layout via `layout "authenticated"`.

**Tech Stack:** Rails 8 views/layouts (ERB), Tailwind + DaisyUI utility classes, Minitest integration tests.

## Global Constraints

- Brand text everywhere: "Sneha's App" (spec: `docs/superpowers/specs/2026-08-16-authenticated-layout-design.md`)
- Footer copyright: "© `<%= Date.current.year %>` Sneha's App", where "Sneha's App" links to `https://github.com/sneharavindra/superpowers-rails-app-template` with `target="_blank" rel="noopener noreferrer"`
- Sign-in/signup/password-reset pages must render exactly as before (no nav, no footer) — verified by not changing their controllers' layout and by keeping `application.html.erb`'s body unchanged
- No new gems, no new nav links beyond brand + sign out, no footer links beyond the GitHub link (per spec's "Out of scope")

---

### Task 1: Extract shared `<head>` partial

**Files:**
- Create: `app/views/layouts/_head.html.erb`
- Modify: `app/views/layouts/application.html.erb`
- Test: `test/integration/layouts_test.rb`

**Interfaces:**
- Produces: partial `layouts/head` — no locals, relies on `content_for(:title)` and `yield :head` exactly as the current inline markup does. Both `application.html.erb` and the new `authenticated.html.erb` (Task 2) render it with `<%= render "layouts/head" %>` inside their own `<head>` tag.

- [ ] **Step 1: Write the failing test**

Create `test/integration/layouts_test.rb`:

```ruby
require "test_helper"

class LayoutsTest < ActionDispatch::IntegrationTest
  test "sign-in page still renders head tags and no nav/footer" do
    get new_session_url
    assert_response :ok
    assert_select "head link[rel=icon]", count: 2
    assert_select "nav", count: 0
    assert_select "footer", count: 0
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/integration/layouts_test.rb`
Expected: FAIL — `new_session_url` should currently work, so this step should actually PASS already (it's establishing the baseline, not testing new behavior). Confirm it passes before moving on; if it fails for any other reason, stop and investigate before proceeding (do not touch layout files yet).

- [ ] **Step 3: Extract the head partial**

Create `app/views/layouts/_head.html.erb` with the exact contents currently inside `<head>...</head>` in `app/views/layouts/application.html.erb` (everything between the `<head>` and `</head>` tags, i.e. the `<title>`, meta tags, `csrf_meta_tags`, `csp_meta_tag`, `yield :head`, the PWA manifest comment, the icon links, and the stylesheet/importmap tags).

Then replace `app/views/layouts/application.html.erb` with:

```erb
<!DOCTYPE html>
<html>
  <head>
    <%= render "layouts/head" %>
  </head>

  <body>
    <main class="container mx-auto mt-28 px-5 flex">
      <%= yield %>
    </main>
  </body>
</html>
```

- [ ] **Step 4: Run test to verify it still passes**

Run: `bin/rails test test/integration/layouts_test.rb`
Expected: PASS

- [ ] **Step 5: Run the full test suite to check for regressions**

Run: `bin/rails test`
Expected: All existing tests still PASS (sign-in/signup/dashboard tests unaffected).

- [ ] **Step 6: Commit**

```bash
git add app/views/layouts/_head.html.erb app/views/layouts/application.html.erb test/integration/layouts_test.rb
git commit -m "Extract shared head partial from application layout"
```

---

### Task 2: Add authenticated layout with nav and footer

**Files:**
- Create: `app/views/layouts/authenticated.html.erb`
- Modify: `app/controllers/dashboard_controller.rb`
- Test: `test/controllers/dashboard_controller_test.rb`

**Interfaces:**
- Consumes: partial `layouts/head` (from Task 1), `Current.user` (from `app/models/current.rb`, delegates `email_address` via `session.user`), route helpers `dashboard_path`, `session_path` (from `resource :session` in `config/routes.rb`, DELETE destroys it per `SessionsController`).
- Produces: layout `"authenticated"` — any controller can opt in with `layout "authenticated"`.

- [ ] **Step 1: Write the failing tests**

Replace `test/controllers/dashboard_controller_test.rb` with:

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

  test "authenticated user sees nav with brand, email, and sign out" do
    user = users(:one)
    post session_url, params: { email_address: user.email_address, password: "password" }

    get dashboard_url
    assert_select "nav" do
      assert_select "a[href=?]", dashboard_path, text: "Sneha's App"
      assert_select "body", text: /#{Regexp.escape(user.email_address)}/
      assert_select "form[action=?][method=post]", session_path do
        assert_select "input[name=_method][value=delete]", count: 1
        assert_select "input[type=submit][value=?]", "Sign out"
      end
    end
  end

  test "authenticated user sees footer with copyright and github link" do
    user = users(:one)
    post session_url, params: { email_address: user.email_address, password: "password" }

    get dashboard_url
    assert_select "footer" do
      assert_select "a[href=?][target=_blank][rel=?]",
        "https://github.com/sneharavindra/superpowers-rails-app-template",
        "noopener noreferrer",
        text: "Sneha's App"
      assert_select "body", text: /#{Date.current.year}/
    end
  end
end
```

- [ ] **Step 2: Run tests to verify the new ones fail**

Run: `bin/rails test test/controllers/dashboard_controller_test.rb`
Expected: The two new tests FAIL (no `<nav>`/`<footer>` yet); the two pre-existing tests still PASS.

- [ ] **Step 3: Create the authenticated layout**

Create `app/views/layouts/authenticated.html.erb`:

```erb
<!DOCTYPE html>
<html>
  <head>
    <%= render "layouts/head" %>
  </head>

  <body class="min-h-screen flex flex-col">
    <nav class="flex items-center justify-between px-5 py-4 border-b border-base-300">
      <%= link_to "Sneha's App", dashboard_path, class: "font-bold text-lg" %>

      <div class="flex items-center gap-4">
        <span class="text-sm text-base-content/70"><%= Current.user.email_address %></span>
        <%= button_to "Sign out", session_path, method: :delete, class: "text-sm underline cursor-pointer bg-transparent border-0 p-0" %>
      </div>
    </nav>

    <main class="container mx-auto px-5 py-8 flex-1">
      <%= yield %>
    </main>

    <footer class="px-5 py-4 border-t border-base-300 text-center text-sm text-base-content/60">
      &copy; <%= Date.current.year %>
      <%= link_to "Sneha's App", "https://github.com/sneharavindra/superpowers-rails-app-template", target: "_blank", rel: "noopener noreferrer", class: "underline" %>
    </footer>
  </body>
</html>
```

- [ ] **Step 4: Wire up the dashboard controller**

Modify `app/controllers/dashboard_controller.rb` to add the layout declaration as the first line inside the class:

```ruby
class DashboardController < ApplicationController
  layout "authenticated"

  def index
  end
end
```

(Keep the existing `index` action body as-is — only add the `layout "authenticated"` line.)

- [ ] **Step 5: Run tests to verify they pass**

Run: `bin/rails test test/controllers/dashboard_controller_test.rb`
Expected: All four tests PASS.

- [ ] **Step 6: Run the full test suite to check for regressions**

Run: `bin/rails test`
Expected: All tests PASS, including `test/integration/layouts_test.rb` from Task 1 (sign-in page still has no nav/footer).

- [ ] **Step 7: Manual visual check**

Using `browser_eval`, sign in and load `/dashboard`; take a snapshot and confirm the nav (brand + email + sign out) and footer (copyright + GitHub link) render, and that clicking "Sign out" redirects to the sign-in page.

- [ ] **Step 8: Commit**

```bash
git add app/views/layouts/authenticated.html.erb app/controllers/dashboard_controller.rb test/controllers/dashboard_controller_test.rb
git commit -m "Add authenticated layout with top nav and footer"
```
