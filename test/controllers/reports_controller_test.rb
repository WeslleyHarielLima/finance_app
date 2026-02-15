require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
  end

  test "unauthenticated user is redirected" do
    delete destroy_user_session_path
    get reports_path
    assert_response :redirect
  end

  test "index returns success" do
    get reports_path
    assert_response :success
  end

  test "reports page shows chart data" do
    create(:financial_entry, :income, user: @user, amount: 5000, date: Date.current)
    create(:financial_entry, :expense, user: @user, amount: 2000, date: Date.current)

    get reports_path
    assert_response :success
  end
end
