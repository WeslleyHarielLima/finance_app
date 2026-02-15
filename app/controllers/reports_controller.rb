class ReportsController < ApplicationController
  before_action :authenticate_user!

  def index
    @current_month = Date.current
    @months_range = 6.months.ago.to_date..Date.current

    # Dados para graficos (chartkick)
    @monthly_expenses = current_user.financial_entries
      .expenses
      .where(date: @months_range)
      .group_by_month(:date)
      .sum(:amount)

    @monthly_incomes = current_user.financial_entries
      .incomes
      .where(date: @months_range)
      .group_by_month(:date)
      .sum(:amount)

    # Gastos por categoria (mes atual)
    @expenses_by_category = current_user.financial_entries
      .expenses
      .this_month
      .joins(:category)
      .group("categories.name")
      .sum(:amount)

    # Resumo mensal
    @total_income_month = current_user.financial_entries.incomes.this_month.sum(:amount)
    @total_expense_month = current_user.financial_entries.expenses.this_month.sum(:amount)
  end
end
