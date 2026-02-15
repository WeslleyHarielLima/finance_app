require "test_helper"

class FinancialEntryTest < ActiveSupport::TestCase
  test "belongs to user" do
    entry = build(:financial_entry, user: nil)
    assert_not entry.valid?
  end

  test "category is optional" do
    entry = build(:financial_entry, category: nil)
    assert entry.valid?
  end

  test "requires description" do
    entry = build(:financial_entry, description: nil)
    assert_not entry.valid?
  end

  test "description minimum length is 2" do
    entry = build(:financial_entry, description: "a")
    assert_not entry.valid?
  end

  test "description maximum length is 100" do
    entry = build(:financial_entry, description: "a" * 101)
    assert_not entry.valid?
  end

  test "requires amount" do
    entry = build(:financial_entry, amount: nil)
    assert_not entry.valid?
  end

  test "amount must be greater than 0" do
    entry = build(:financial_entry, amount: 0)
    assert_not entry.valid?

    entry2 = build(:financial_entry, amount: -10)
    assert_not entry2.valid?
  end

  test "requires entry_type" do
    entry = build(:financial_entry, entry_type: nil)
    assert_not entry.valid?
  end

  test "requires date" do
    entry = build(:financial_entry, date: nil)
    assert_not entry.valid?
  end

  test "enum entry_type has income and expense" do
    assert_equal({ "income" => "income", "expense" => "expense" }, FinancialEntry.entry_types)
  end

  test "scope this_month returns only current month entries" do
    user = create(:user)
    current = create(:financial_entry, user: user, date: Date.current)
    old = create(:financial_entry, user: user, date: 2.months.ago)

    results = user.financial_entries.this_month
    assert_includes results, current
    assert_not_includes results, old
  end

  test "scope income returns only income entries" do
    user = create(:user)
    income = create(:financial_entry, :income, user: user)
    expense = create(:financial_entry, :expense, user: user)

    results = user.financial_entries.income
    assert_includes results, income
    assert_not_includes results, expense
  end

  test "scope expense returns only expense entries" do
    user = create(:user)
    income = create(:financial_entry, :income, user: user)
    expense = create(:financial_entry, :expense, user: user)

    results = user.financial_entries.expense
    assert_includes results, expense
    assert_not_includes results, income
  end

  test "scope recurring returns only recurring entries" do
    user = create(:user)
    recurring = create(:financial_entry, :recurring, user: user)
    normal = create(:financial_entry, user: user, recurring: false)

    results = user.financial_entries.recurring
    assert_includes results, recurring
    assert_not_includes results, normal
  end

  test "generate_recurring_for_month creates entries from recurring templates" do
    user = create(:user)
    create(:financial_entry, :recurring, user: user, description: "Aluguel", amount: 1500, recurring_day: 10)

    assert_difference -> { user.financial_entries.count }, 1 do
      FinancialEntry.generate_recurring_for_month(user)
    end

    generated = user.financial_entries.where(description: "Aluguel", recurring: false).last
    assert_not_nil generated
    assert_equal 1500, generated.amount
  end

  test "generate_recurring_for_month does not duplicate entries" do
    user = create(:user)
    create(:financial_entry, :recurring, user: user, description: "Aluguel", amount: 1500, recurring_day: 10)

    FinancialEntry.generate_recurring_for_month(user)

    assert_no_difference -> { user.financial_entries.count } do
      FinancialEntry.generate_recurring_for_month(user)
    end
  end
end
