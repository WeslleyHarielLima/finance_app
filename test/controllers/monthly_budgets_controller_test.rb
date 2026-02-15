require "test_helper"

class MonthlyBudgetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
  end

  test "unauthenticated user is redirected" do
    delete destroy_user_session_path
    get monthly_budgets_path
    assert_response :redirect
  end

  test "index lists budgets" do
    create(:monthly_budget, user: @user)
    get monthly_budgets_path
    assert_response :success
  end

  test "create budget with valid params" do
    assert_difference -> { @user.monthly_budgets.count }, 1 do
      post monthly_budgets_path, params: {
        monthly_budget: { month: Date.current.beginning_of_month, total_amount: 3000 }
      }
    end
    assert_redirected_to monthly_budgets_path
  end

  test "create budget with invalid params" do
    post monthly_budgets_path, params: {
      monthly_budget: { month: nil, total_amount: -1 }
    }
    assert_response :unprocessable_entity
  end

  test "update budget" do
    budget = create(:monthly_budget, user: @user)
    patch monthly_budget_path(budget), params: {
      monthly_budget: { total_amount: 5000 }
    }
    assert_redirected_to monthly_budgets_path
    assert_equal 5000, budget.reload.total_amount
  end
end
