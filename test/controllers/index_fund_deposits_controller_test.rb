require 'test_helper'

class IndexFundDepositsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get index_fund_deposits_new_url
    assert_response :success
  end

end
