require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
  end

  test "unauthenticated user is redirected" do
    delete destroy_user_session_path
    get dashboard_path
    assert_response :redirect
  end

  test "authenticated user can access dashboard" do
    get dashboard_path
    assert_response :success
  end

  test "dashboard shows current month data" do
    create(:financial_entry, :income, user: @user, amount: 5000, date: Date.current)
    create(:financial_entry, :expense, user: @user, amount: 2000, date: Date.current)

    get dashboard_path
    assert_response :success
  end

  test "dashboard shows budget alert when over 70%" do
    budget = create(:monthly_budget, user: @user, total_amount: 1000, month: Date.current.beginning_of_month)
    create(:financial_entry, :expense, user: @user, amount: 800, date: Date.current)

    get dashboard_path
    assert_response :success
    assert_match(/ja usou/, response.body)
  end
end
