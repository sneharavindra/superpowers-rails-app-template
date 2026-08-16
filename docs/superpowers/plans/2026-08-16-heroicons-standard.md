# Heroicons Standard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install the `heroicon` gem, configure `:outline` as the default variant, and document Heroicons as the project's standard icon library in `AGENTS.md`.

**Architecture:** The `heroicon` gem (bharget/heroicon) provides a `heroicon(name, variant:, options:)` view helper that renders inline SVG server-side by reading bundled SVG files from its own asset path — no JS/npm involvement. Its installer generates `config/initializers/heroicon.rb` (default variant config) and `app/helpers/heroicon_helper.rb` (a one-line module that includes the gem engine's helpers into all views).

**Tech Stack:** Ruby gem `heroicon` (~> 1.0), Rails view helpers, Minitest.

## Global Constraints

- Default variant: `:outline` (spec: `docs/superpowers/specs/2026-08-16-heroicons-standard-design.md`)
- No migration of existing views — nothing in the app currently uses icons
- No custom wrapper/component around the `heroicon` helper
- Note: this gem's official installer generates `app/helpers/heroicon_helper.rb`. The project's view conventions prohibit custom helpers (logic belongs in ViewComponents), but this file contains zero app logic — it's a one-line `include Heroicon::Engine.helpers` required by the gem's own installation path, not a helper we're authoring. Keep it as generated; do not add anything else to it.

---

### Task 1: Install and configure the gem

**Files:**
- Modify: `Gemfile`, `Gemfile.lock` (via `bundle add`)
- Create: `config/initializers/heroicon.rb` (via generator)
- Create: `app/helpers/heroicon_helper.rb` (via generator)
- Test: `test/helpers/heroicon_helper_test.rb`

**Interfaces:**
- Produces: view helper `heroicon(name, variant: :outline, options: {}, path_options: {})` returning a `raw` SVG string, available in all views/helper tests via `HeroiconHelper`.

- [ ] **Step 1: Add the gem**

```bash
bundle add heroicon --version "~> 1.0"
```

Verify `Gemfile` now has `gem "heroicon", "~> 1.0"` and `Gemfile.lock` includes `heroicon (1.0.0)`.

- [ ] **Step 2: Run the installer**

```bash
bin/rails g heroicon:install
```

Expected: creates `config/initializers/heroicon.rb` and `app/helpers/heroicon_helper.rb`.

- [ ] **Step 3: Set the default variant to outline**

Edit `config/initializers/heroicon.rb` — change the generated `config.variant = :solid` line to:

```ruby
config.variant = :outline # Options are :solid, :outline and :mini
```

- [ ] **Step 4: Write the failing test**

Create `test/helpers/heroicon_helper_test.rb`:

```ruby
require "test_helper"

class HeroiconHelperTest < ActionView::TestCase
  test "renders an outline icon by default" do
    svg = heroicon("check")

    assert_includes svg, "<svg"
    assert_includes svg, "check"
  end

  test "outline is the configured default variant" do
    assert_equal :outline, Heroicon.configuration.variant
  end
end
```

- [ ] **Step 5: Run the test to verify it fails**

Run: `bin/rails test test/helpers/heroicon_helper_test.rb`
Expected: FAIL — `Heroicon.configuration.variant` is still `:solid` because Step 3 hasn't been applied yet if run out of order, or the gem/generator files don't exist yet if Steps 1-2 haven't run. Run this only after Steps 1-3 are actually applied, to confirm you understand what "passing" looks like; if it already passes at this point, that's expected since Steps 1-3 already made the change — proceed to Step 6 to confirm.

- [ ] **Step 6: Run the test to verify it passes**

Run: `bin/rails test test/helpers/heroicon_helper_test.rb`
Expected: PASS (2 runs, 0 failures)

- [ ] **Step 7: Run the full test suite to check for regressions**

Run: `bin/rails test`
Expected: All tests PASS.

- [ ] **Step 8: Run rubocop on new Ruby files**

Run: `bundle exec rubocop config/initializers/heroicon.rb app/helpers/heroicon_helper.rb test/helpers/heroicon_helper_test.rb`
Expected: No offenses. If `app/helpers/heroicon_helper.rb` (gem-generated) has offenses, fix formatting only — don't change its logic.

- [ ] **Step 9: Commit**

```bash
git add Gemfile Gemfile.lock config/initializers/heroicon.rb app/helpers/heroicon_helper.rb test/helpers/heroicon_helper_test.rb
git commit -m "Install heroicon gem with outline as default variant"
```

---

### Task 2: Document the standard in AGENTS.md

**Files:**
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: nothing (documentation only)

- [ ] **Step 1: Add an Icons section**

In `AGENTS.md`, add a new `## Icons` section immediately after the existing `## Frontend` section:

```markdown
## Icons

[Heroicons](https://heroicons.com/) via the `heroicon` gem is the standard icon library — DaisyUI does not ship icons. Default variant is `:outline` (set in `config/initializers/heroicon.rb`). Use the helper directly in views:

```erb
<%= heroicon "check", options: { class: "size-5" } %>
```

Override per-icon with `variant: :solid` or `variant: :mini` when needed.
```

- [ ] **Step 2: Verify the file renders sensibly**

Run: `cat AGENTS.md` and confirm the new section reads correctly between "Frontend" and the next section ("Testing"), with no broken Markdown (matching code fence count, etc).

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "Document Heroicons as the standard icon library"
```
