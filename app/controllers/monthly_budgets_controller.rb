class MonthlyBudgetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_budget, only: [:edit, :update]

  def index
    @budgets = current_user.monthly_budgets.order(month: :desc)
    @current_budget = current_user.monthly_budgets
      .find_by(month: Date.current.beginning_of_month)
  end

  def new
    @budget = current_user.monthly_budgets.new(month: Date.current.beginning_of_month)
  end

  def create
    @budget = current_user.monthly_budgets.new(budget_params)
    if @budget.save
      redirect_to monthly_budgets_path, notice: "Orcamento definido com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @budget.update(budget_params)
      redirect_to monthly_budgets_path, notice: "Orcamento atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_budget
    @budget = current_user.monthly_budgets.find(params[:id])
  end

  def budget_params
    params.require(:monthly_budget).permit(:month, :total_amount)
  end
end
