require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "renders sign-up form" do
    get new_registration_url
    assert_response :ok
    assert_select "form"
  end

  test "creates account and user then redirects to dashboard" do
    assert_difference([ "Account.count", "User.count" ], 1) do
      post registrations_url, params: {
        name: "Sneha Ravindra",
        email_address: "sneha@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    end

    assert_redirected_to dashboard_url
    assert_equal "Sneha's Org", Account.last.name
  end

  test "re-renders form on invalid submission" do
    assert_no_difference("User.count") do
      post registrations_url, params: {
        name: "Sneha Ravindra",
        email_address: "",
        password: "password123",
        password_confirmation: "password123"
      }
    end

    assert_response :unprocessable_entity
  end

  test "first name fallback when name has no spaces" do
    post registrations_url, params: {
      name: "Sneha",
      email_address: "sneha2@example.com",
      password: "password123",
      password_confirmation: "password123"
    }

    assert_equal "Sneha's Org", Account.last.name
  end
end
