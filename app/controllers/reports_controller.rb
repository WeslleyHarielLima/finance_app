class ReportsController < ApplicationController
  before_action :authenticate_user!

  def index
    @current_month = Date.current
    @months_range = 6.months.ago.to_date..Date.current

    # Dados para graficos (chartkick)
    @monthly_expenses = current_user.financial_entries
      .expense
      .where(date: @months_range)
      .group_by_month(:date)
      .sum(:amount)

    @monthly_incomes = current_user.financial_entries
      .income
      .where(date: @months_range)
      .group_by_month(:date)
      .sum(:amount)

    # Gastos por categoria (mes atual)
    @expenses_by_category = current_user.financial_entries
      .expense
      .this_month
      .joins(:category)
      .group("categories.name")
      .sum(:amount)

    # Resumo mensal
    @total_income_month = current_user.financial_entries.income.this_month.sum(:amount)
    @total_expense_month = current_user.financial_entries.expense.this_month.sum(:amount)

    # Calendario do cartao de credito
    @cc_month = if params[:cc_month].present?
      Date.parse("#{params[:cc_month]}-01")
    else
      Date.current.beginning_of_month
    end

    @cc_charges = current_user.credit_card_charges
      .includes(:category)
      .select { |c| c.active_in_month?(@cc_month) }

    @cc_installment_charges = @cc_charges.reject(&:recurring?)
    @cc_recurring_charges = @cc_charges.select(&:recurring?)
    @cc_month_total = @cc_charges.sum(&:installment_amount)
  end
end
