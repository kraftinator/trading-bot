require 'test_helper'

class TradersControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get traders_edit_url
    assert_response :success
  end

  test "should get index" do
    get traders_index_url
    assert_response :success
  end

  test "should get new" do
    get traders_new_url
    assert_response :success
  end

  test "should get show" do
    get traders_show_url
    assert_response :success
  end

end
