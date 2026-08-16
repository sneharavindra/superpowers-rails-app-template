require "test_helper"

class LayoutsTest < ActionDispatch::IntegrationTest
  test "sign-in page still renders head tags and no nav/footer" do
    get new_session_url
    assert_response :ok
    assert_select "head link[rel=icon]", count: 2
    assert_select "nav", count: 0
    assert_select "footer", count: 0
  end
end
