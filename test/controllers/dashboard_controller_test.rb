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
