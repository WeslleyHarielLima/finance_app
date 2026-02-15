class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    entries = current_user.financial_entries.this_month

    @total_income = entries.income.sum(:amount)
    @total_expenses = entries.expense.sum(:amount)
    @balance = @total_income - @total_expenses

    @recent_transactions = current_user.financial_entries
      .includes(:category)
      .order(date: :desc, created_at: :desc)
      .limit(5)
  end
end
