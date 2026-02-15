require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "has many financial_entries" do
    user = create(:user)
    assert_respond_to user, :financial_entries
  end

  test "has many categories" do
    user = create(:user)
    assert_respond_to user, :categories
  end

  test "has many monthly_budgets" do
    user = create(:user)
    assert_respond_to user, :monthly_budgets
  end

  test "destroys associated financial_entries" do
    user = create(:user)
    create(:financial_entry, user: user)
    assert_difference -> { FinancialEntry.count }, -1 do
      user.destroy
    end
  end

  test "requires name" do
    user = build(:user, name: nil)
    assert_not user.valid?
  end

  test "monthly_income must be >= 0 when present" do
    user = build(:user, monthly_income: -1)
    assert_not user.valid?
  end

  test "monthly_income can be nil" do
    user = build(:user, monthly_income: nil)
    assert user.valid?
  end

  test "balance returns income minus expenses" do
    user = create(:user)
    create(:financial_entry, :income, user: user, amount: 5000)
    create(:financial_entry, :expense, user: user, amount: 2000)

    assert_equal 3000, user.balance
  end

  test "balance_for_month returns monthly balance" do
    user = create(:user)
    create(:financial_entry, :income, user: user, amount: 3000, date: Date.current)
    create(:financial_entry, :expense, user: user, amount: 1000, date: Date.current)
    create(:financial_entry, :income, user: user, amount: 9999, date: 2.months.ago)

    assert_equal 2000, user.balance_for_month(Date.current)
  end

  test "income_for_month returns only income for given month" do
    user = create(:user)
    create(:financial_entry, :income, user: user, amount: 3000, date: Date.current)
    create(:financial_entry, :expense, user: user, amount: 1000, date: Date.current)

    assert_equal 3000, user.income_for_month(Date.current)
  end

  test "expenses_for_month returns only expenses for given month" do
    user = create(:user)
    create(:financial_entry, :income, user: user, amount: 3000, date: Date.current)
    create(:financial_entry, :expense, user: user, amount: 1500, date: Date.current)

    assert_equal 1500, user.expenses_for_month(Date.current)
  end
end
