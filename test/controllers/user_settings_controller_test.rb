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
