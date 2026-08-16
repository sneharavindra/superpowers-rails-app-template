require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "superadmin defaults to false" do
    account = accounts(:one)
    user = User.create!(
      account: account,
      email_address: "test_superadmin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert_equal false, user.superadmin
  end

  test "superadmin can be set to true" do
    account = accounts(:one)
    user = User.create!(
      account: account,
      email_address: "admin_superadmin@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true
    )
    assert user.superadmin
  end
end
