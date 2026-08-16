# Nav User Dropdown Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Collapse the nav's avatar, email, and sign-out button into a single avatar-triggered dropdown with icons.

**Architecture:** Replace the flat `<div class="flex items-center gap-4">` in `app/views/layouts/authenticated.html.erb` with a DaisyUI `details`/`summary` dropdown: the avatar is the `summary` (trigger), and a `menu` inside `dropdown-content` holds the email (labeled with a `user` icon) and the existing sign-out `button_to` (labeled with an `arrow-right-on-rectangle` icon).

**Tech Stack:** ERB, DaisyUI `dropdown`/`menu` components, `heroicon` gem (already installed, `:outline` default), Minitest.

## Global Constraints

- Dropdown trigger is the avatar; no JS/Stimulus (spec: `docs/superpowers/specs/2026-08-16-nav-user-dropdown-design.md`)
- Icons: `user` for the email row, `arrow-right-on-rectangle` for sign out, both default `:outline` variant
- `dropdown-end` placement
- Sign-out behavior unchanged (still `button_to session_path, method: :delete`)

---

### Task 1: Replace nav user info with a dropdown

**Files:**
- Modify: `app/views/layouts/authenticated.html.erb`
- Modify: `test/controllers/dashboard_controller_test.rb`

**Interfaces:**
- Consumes: `heroicon(name, options: {})` helper (from `app/helpers/heroicon_helper.rb`, installed in a prior task), `Current.user.email_address`, `dashboard_path`, `session_path`.

- [ ] **Step 1: Update the failing tests first**

The existing tests `"authenticated user sees nav with brand, email, and sign out"` currently assert `span` and `form` as direct children of `nav`. They'll now be nested inside the dropdown. Replace that test in `test/controllers/dashboard_controller_test.rb` with:

```ruby
  test "authenticated user sees nav with brand and a user dropdown" do
    user = users(:one)
    post session_url, params: { email_address: user.email_address, password: "password" }

    get dashboard_url
    assert_select "nav" do
      assert_select "a[href=?]", dashboard_path, text: "Sneha's App"
      assert_select "details.dropdown" do
        assert_select "summary svg", count: 0 # avatar trigger has no icon, just initials
        assert_select "summary .avatar"
        assert_select "li", text: /#{Regexp.escape(user.email_address)}/ do
          assert_select "svg"
        end
        assert_select "form[action=?][method=post]", session_path do
          assert_select "input[name=_method][value=delete]", count: 1
          assert_select "button[type=submit] svg"
          assert_select "button[type=submit]", text: /Sign out/
        end
      end
    end
  end
```

This replaces the old test with the same name in the file — keep the other three tests (`unauthenticated user...`, `authenticated user sees dashboard`, `authenticated user sees footer...`) unchanged.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bin/rails test test/controllers/dashboard_controller_test.rb`
Expected: FAIL — `details.dropdown` doesn't exist yet in the nav.

- [ ] **Step 3: Update the layout**

In `app/views/layouts/authenticated.html.erb`, replace the `<div class="flex items-center gap-4">...</div>` block (lines 11-19) with:

```erb
      <details class="dropdown dropdown-end">
        <summary class="avatar avatar-placeholder cursor-pointer list-none">
          <div class="bg-neutral text-neutral-content w-8 rounded-full">
            <span class="text-xs"><%= Current.user.email_address.first.upcase %></span>
          </div>
        </summary>

        <ul class="dropdown-content menu bg-base-100 rounded-box z-1 w-56 p-2 shadow-sm">
          <li class="menu-title flex flex-row items-center gap-2 text-base-content">
            <%= heroicon "user", options: { class: "size-4" } %>
            <span class="text-sm"><%= Current.user.email_address %></span>
          </li>
          <li>
            <%= button_to session_path, method: :delete, class: "flex items-center gap-2 w-full text-left bg-transparent border-0 cursor-pointer" do %>
              <%= heroicon "arrow-right-on-rectangle", options: { class: "size-4" } %>
              Sign out
            <% end %>
          </li>
        </ul>
      </details>
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bin/rails test test/controllers/dashboard_controller_test.rb`
Expected: PASS (4 runs, 0 failures)

- [ ] **Step 5: Run the full test suite to check for regressions**

Run: `bin/rails test`
Expected: All tests PASS.

- [ ] **Step 6: Run rubocop**

Run: `bundle exec rubocop app/controllers/dashboard_controller.rb test/controllers/dashboard_controller_test.rb`
Expected: No offenses. (The `.erb` layout file isn't Ruby-lintable by rubocop directly — skip it.)

- [ ] **Step 7: Manual visual check**

Using curl with an authenticated session cookie (or `browser_eval` if console output is working), load `/dashboard` and confirm: the avatar is clickable and opens a dropdown, the dropdown shows the email with a user icon and "Sign out" with a logout icon, and clicking "Sign out" still signs out correctly.

- [ ] **Step 8: Commit**

```bash
git add app/views/layouts/authenticated.html.erb test/controllers/dashboard_controller_test.rb docs/superpowers/plans/2026-08-16-nav-user-dropdown.md
git commit -m "Collapse nav user info into an avatar-triggered dropdown"
```
