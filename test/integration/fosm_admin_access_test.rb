require "test_helper"

class FosmAdminAccessTest < ActionDispatch::IntegrationTest
  test "unauthenticated user cannot reach fosm admin" do
    get "/fosm/admin"
    assert_redirected_to "/session/new"
  end

  test "authenticated non-superadmin is redirected to root" do
    user = users(:one)
    post session_url, params: { email_address: user.email_address, password: "password" }

    get "/fosm/admin"
    assert_redirected_to "/"
  end

  test "superadmin can access fosm admin" do
    user = users(:one)
    user.update!(superadmin: true)
    post session_url, params: { email_address: user.email_address, password: "password" }

    get "/fosm/admin"
    assert_response :ok
  end
end
