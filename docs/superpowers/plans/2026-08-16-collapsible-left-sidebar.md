# Collapsible Left Sidebar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a left sidebar to the authenticated layout, permanently visible on large screens and collapsible behind a hamburger toggle on small screens.

**Architecture:** Wrap the existing `main` in a DaisyUI `drawer` (`lg:drawer-open`), with `drawer-side` holding a `menu` sidebar (one "Dashboard" link with a `home` icon). Add a hamburger toggle (`bars-3` icon) to the top nav, visible only below the `lg` breakpoint (`lg:hidden`), pointing at the drawer's checkbox input. Footer stays outside the drawer, full-width, unchanged. Pure CSS checkbox toggle — no JS/Stimulus.

**Tech Stack:** ERB, DaisyUI `drawer`/`menu` components, `heroicon` gem, Minitest.

## Global Constraints

- Authenticated layout only — `application.html.erb` unchanged (spec: `docs/superpowers/specs/2026-08-16-collapsible-left-sidebar-design.md`)
- Sidebar content: single "Dashboard" link with `home` icon, styled active
- Toggle button: `bars-3` icon, `lg:hidden`, no JS
- Footer stays full-width, outside the drawer

---

### Task 1: Add the drawer and sidebar

**Files:**
- Modify: `app/views/layouts/authenticated.html.erb`
- Modify: `test/controllers/dashboard_controller_test.rb`

**Interfaces:**
- Consumes: `heroicon(name, options: {})` helper, `dashboard_path`.

- [ ] **Step 1: Write the failing test**

Add a new test to `test/controllers/dashboard_controller_test.rb` (after the existing nav dropdown test):

```ruby
  test "authenticated user sees a collapsible sidebar with a dashboard link" do
    user = users(:one)
    post session_url, params: { email_address: user.email_address, password: "password" }

    get dashboard_url
    assert_select "label[for=sidebar-drawer].lg\\:hidden svg"
    assert_select "input#sidebar-drawer[type=checkbox].drawer-toggle"
    assert_select "div.drawer-side" do
      assert_select "a[href=?]", dashboard_path, text: /Dashboard/ do
        assert_select "svg"
      end
    end
  end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bin/rails test test/controllers/dashboard_controller_test.rb`
Expected: FAIL — no `drawer-side` or `sidebar-drawer` elements exist yet.

- [ ] **Step 3: Update the layout**

Replace the full contents of `app/views/layouts/authenticated.html.erb` with:

```erb
<!DOCTYPE html>
<html>
  <head>
    <%= render "layouts/head" %>
  </head>

  <body class="min-h-screen flex flex-col">
    <nav class="flex items-center justify-between px-5 py-4 border-b border-base-300">
      <div class="flex items-center gap-3">
        <label for="sidebar-drawer" class="btn btn-ghost btn-square lg:hidden" aria-label="Open sidebar">
          <%= heroicon "bars-3", options: { class: "size-5" } %>
        </label>
        <%= link_to "Sneha's App", dashboard_path, class: "font-bold text-lg" %>
      </div>

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
    </nav>

    <div class="drawer lg:drawer-open flex-1">
      <input id="sidebar-drawer" type="checkbox" class="drawer-toggle" />

      <div class="drawer-content">
        <main class="container mx-auto px-5 py-8">
          <%= yield %>
        </main>
      </div>

      <div class="drawer-side">
        <label for="sidebar-drawer" aria-label="close sidebar" class="drawer-overlay"></label>
        <ul class="menu bg-base-100 min-h-full w-56 p-4 border-r border-base-300">
          <li>
            <%= link_to dashboard_path, class: "menu-active flex items-center gap-2" do %>
              <%= heroicon "home", options: { class: "size-4" } %>
              Dashboard
            <% end %>
          </li>
        </ul>
      </div>
    </div>

    <footer class="px-5 py-4 border-t border-base-300 text-center text-sm text-base-content/60">
      &copy; <%= Date.current.year %>
      <%= link_to "Sneha's App", "https://github.com/sneharavindra/superpowers-rails-app-template", target: "_blank", rel: "noopener noreferrer", class: "underline" %>
    </footer>
  </body>
</html>
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bin/rails test test/controllers/dashboard_controller_test.rb`
Expected: PASS (5 runs, 0 failures)

- [ ] **Step 5: Run the full test suite to check for regressions**

Run: `bin/rails test`
Expected: All tests PASS.

- [ ] **Step 6: Run rubocop**

Run: `bundle exec rubocop app/controllers/dashboard_controller.rb test/controllers/dashboard_controller_test.rb`
Expected: No offenses.

- [ ] **Step 7: Manual visual check**

Using an authenticated curl session (as in prior tasks), fetch `/dashboard` and confirm the response HTML contains: the hamburger `label`+`svg` in the nav, the `drawer`/`drawer-toggle`/`drawer-side` structure, and the "Dashboard" sidebar link with its `home` icon. Since the collapse behavior is pure CSS (no JS to exercise via curl), markup presence is the verification; visually confirm in a browser if `browser_eval` console output is available this session.

- [ ] **Step 8: Commit**

```bash
git add app/views/layouts/authenticated.html.erb test/controllers/dashboard_controller_test.rb docs/superpowers/plans/2026-08-16-collapsible-left-sidebar.md
git commit -m "Add collapsible left sidebar to the authenticated layout"
```
