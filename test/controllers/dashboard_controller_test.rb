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
      assert_select "span", text: user.email_address
      assert_select "form[action=?][method=post]", session_path do
        assert_select "input[name=_method][value=delete]", count: 1
        assert_select "button[type=submit]", text: "Sign out"
      end
    end
  end

  test "authenticated user sees footer with copyright and github link" do
    user = users(:one)
    post session_url, params: { email_address: user.email_address, password: "password" }

    get dashboard_url
    assert_select "footer", text: /#{Date.current.year}/ do
      assert_select "a[href=?][target=_blank][rel=?]",
        "https://github.com/sneharavindra/superpowers-rails-app-template",
        "noopener noreferrer",
        text: "Sneha's App"
    end
  end
end
