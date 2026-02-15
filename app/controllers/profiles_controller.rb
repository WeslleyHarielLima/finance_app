class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @stats = {
      total_entries: current_user.financial_entries.count,
      total_income: current_user.financial_entries.income.sum(:amount),
      total_expenses: current_user.financial_entries.expense.sum(:amount),
      categories_count: current_user.categories.count,
      member_since: current_user.created_at
    }
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      redirect_to profile_path, notice: 'Perfil atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :monthly_income, :currency, :timezone)
  end
end
