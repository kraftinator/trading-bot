require 'test_helper'

class TradingPairsControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get trading_pairs_edit_url
    assert_response :success
  end

  test "should get index" do
    get trading_pairs_index_url
    assert_response :success
  end

  test "should get new" do
    get trading_pairs_new_url
    assert_response :success
  end

  test "should get show" do
    get trading_pairs_show_url
    assert_response :success
  end

end
