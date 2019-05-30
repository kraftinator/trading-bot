require 'test_helper'

class IndexFundCoinsControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get index_fund_coins_edit_url
    assert_response :success
  end

  test "should get new" do
    get index_fund_coins_new_url
    assert_response :success
  end

end
