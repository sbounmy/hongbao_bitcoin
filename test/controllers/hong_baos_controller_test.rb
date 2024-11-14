require "test_helper"

class HongBaosControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get hong_baos_new_url
    assert_response :success
  end

  test "should get create" do
    get hong_baos_create_url
    assert_response :success
  end

  test "should get show" do
    get hong_baos_show_url
    assert_response :success
  end
end
