require "test_helper"

class BudgetManagementTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
  end

  test "create budget and see progress" do
    post monthly_budgets_path, params: {
      monthly_budget: { month: Date.current.beginning_of_month, total_amount: 2000 }
    }
    assert_redirected_to monthly_budgets_path

    budget = @user.monthly_budgets.last
    assert_equal 2000, budget.total_amount.to_f

    get monthly_budgets_path
    assert_response :success
  end

  test "budget alert appears on dashboard when over 70%" do
    create(:monthly_budget, user: @user, total_amount: 1000, month: Date.current.beginning_of_month)
    create(:financial_entry, :expense, user: @user, amount: 800, date: Date.current)

    get dashboard_path
    assert_response :success
    assert_match "budget-alert", response.body
  end

  test "no budget alert when under 70%" do
    create(:monthly_budget, user: @user, total_amount: 1000, month: Date.current.beginning_of_month)
    create(:financial_entry, :expense, user: @user, amount: 300, date: Date.current)

    get dashboard_path
    assert_response :success
    assert_no_match "budget-alert", response.body
  end

  test "update budget amount" do
    budget = create(:monthly_budget, user: @user, total_amount: 1000)
    patch monthly_budget_path(budget), params: {
      monthly_budget: { total_amount: 3000 }
    }
    assert_redirected_to monthly_budgets_path
    assert_equal 3000, budget.reload.total_amount.to_f
  end
end
