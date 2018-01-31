require 'test_helper'

class AuthorizationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get authorizations_new_url
    assert_response :success
  end

end
