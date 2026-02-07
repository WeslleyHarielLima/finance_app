class DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @user = current_user
    @current_month = Date.current.beginning_of_month..Date.current.end_of_month
    
    # Buscar transações do mês atual
    @transactions = current_user.financial_entries.where(date: @current_month)
    
    # Calcular totais
    @total_income = @transactions.where(entry_type: 'income').sum(:amount) || 0
    @total_expenses = @transactions.where(entry_type: 'expense').sum(:amount) || 0
    @balance = @total_income - @total_expenses
    
    # Últimas transações
    @recent_transactions = current_user.financial_entries
      .order(date: :desc, created_at: :desc)
      .limit(5)
      .includes(:category)
  end
end
