class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    entries = current_user.financial_entries.this_month

    @total_income = Rails.cache.fetch("user_#{current_user.id}_income_#{Date.current.month}", expires_in: 10.minutes) do
      entries.income.sum(:amount)
    end

    @total_expenses = Rails.cache.fetch("user_#{current_user.id}_expenses_#{Date.current.month}", expires_in: 10.minutes) do
      entries.expense.sum(:amount)
    end

    @balance = @total_income - @total_expenses

    @recent_transactions = current_user.financial_entries
      .includes(:category)
      .order(date: :desc, created_at: :desc)
      .limit(5)

    # Alerta de orcamento
    @current_budget = current_user.monthly_budgets
      .find_by(month: Date.current.beginning_of_month)

    # Grafico dos ultimos 7 dias
    @daily_expenses = current_user.financial_entries
      .expense
      .where(date: 7.days.ago..Date.current)
      .group(:date)
      .sum(:amount)

    # Top categorias do mes
    @top_categories = current_user.financial_entries
      .expense
      .this_month
      .joins(:category)
      .group('categories.name')
      .order('sum_amount DESC')
      .limit(5)
      .sum(:amount)
  end
end
