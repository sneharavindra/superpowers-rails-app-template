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
