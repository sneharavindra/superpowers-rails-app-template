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
