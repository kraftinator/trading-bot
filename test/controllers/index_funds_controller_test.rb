require 'test_helper'

class IndexFundsControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get index_funds_edit_url
    assert_response :success
  end

  test "should get index" do
    get index_funds_index_url
    assert_response :success
  end

  test "should get new" do
    get index_funds_new_url
    assert_response :success
  end

  test "should get show" do
    get index_funds_show_url
    assert_response :success
  end

end
