require "test_helper"

class MonthlyBudgetTest < ActiveSupport::TestCase
  test "belongs to user" do
    budget = build(:monthly_budget, user: nil)
    assert_not budget.valid?
  end

  test "requires month" do
    budget = build(:monthly_budget, month: nil)
    assert_not budget.valid?
  end

  test "requires total_amount" do
    budget = build(:monthly_budget, total_amount: nil)
    assert_not budget.valid?
  end

  test "total_amount must be greater than 0" do
    budget = build(:monthly_budget, total_amount: 0)
    assert_not budget.valid?

    budget2 = build(:monthly_budget, total_amount: -100)
    assert_not budget2.valid?
  end

  test "month must be unique per user" do
    user = create(:user)
    create(:monthly_budget, user: user, month: Date.current.beginning_of_month)

    duplicate = build(:monthly_budget, user: user, month: Date.current.beginning_of_month)
    assert_not duplicate.valid?
  end

  test "spent returns total expenses for the month" do
    user = create(:user)
    budget = create(:monthly_budget, user: user, month: Date.current.beginning_of_month)
    create(:financial_entry, :expense, user: user, amount: 500, date: Date.current)
    create(:financial_entry, :expense, user: user, amount: 300, date: Date.current)

    assert_equal 800, budget.spent
  end

  test "remaining returns total_amount minus spent" do
    user = create(:user)
    budget = create(:monthly_budget, user: user, total_amount: 2000, month: Date.current.beginning_of_month)
    create(:financial_entry, :expense, user: user, amount: 800, date: Date.current)

    assert_equal 1200, budget.remaining
  end

  test "percentage_used returns correct percentage" do
    user = create(:user)
    budget = create(:monthly_budget, user: user, total_amount: 1000, month: Date.current.beginning_of_month)
    create(:financial_entry, :expense, user: user, amount: 750, date: Date.current)

    assert_equal 75.0, budget.percentage_used
  end

  test "exceeded? returns true when over budget" do
    user = create(:user)
    budget = create(:monthly_budget, user: user, total_amount: 500, month: Date.current.beginning_of_month)
    create(:financial_entry, :expense, user: user, amount: 600, date: Date.current)

    assert budget.exceeded?
  end

  test "alert_level returns :normal when under 70%" do
    user = create(:user)
    budget = create(:monthly_budget, user: user, total_amount: 1000, month: Date.current.beginning_of_month)
    create(:financial_entry, :expense, user: user, amount: 500, date: Date.current)

    assert_equal :normal, budget.alert_level
  end

  test "alert_level returns :warning when between 71-90%" do
    user = create(:user)
    budget = create(:monthly_budget, user: user, total_amount: 1000, month: Date.current.beginning_of_month)
    create(:financial_entry, :expense, user: user, amount: 800, date: Date.current)

    assert_equal :warning, budget.alert_level
  end

  test "alert_level returns :danger when between 91-100%" do
    user = create(:user)
    budget = create(:monthly_budget, user: user, total_amount: 1000, month: Date.current.beginning_of_month)
    create(:financial_entry, :expense, user: user, amount: 950, date: Date.current)

    assert_equal :danger, budget.alert_level
  end

  test "alert_level returns :exceeded when over 100%" do
    user = create(:user)
    budget = create(:monthly_budget, user: user, total_amount: 1000, month: Date.current.beginning_of_month)
    create(:financial_entry, :expense, user: user, amount: 1200, date: Date.current)

    assert_equal :exceeded, budget.alert_level
  end

  test "alert_message returns nil for normal level" do
    user = create(:user)
    budget = create(:monthly_budget, user: user, total_amount: 1000, month: Date.current.beginning_of_month)

    assert_nil budget.alert_message
  end

  test "alert_message returns warning message" do
    user = create(:user)
    budget = create(:monthly_budget, user: user, total_amount: 1000, month: Date.current.beginning_of_month)
    create(:financial_entry, :expense, user: user, amount: 800, date: Date.current)

    assert_match(/ja usou/, budget.alert_message)
  end
end
