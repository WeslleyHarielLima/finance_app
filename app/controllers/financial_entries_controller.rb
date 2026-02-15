class FinancialEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_financial_entry, only: [:edit, :update, :destroy]

  def index
    @financial_entries = current_user.financial_entries
      .includes(:category)
      .order(date: :desc, created_at: :desc)

    if params[:entry_type].in?(%w[income expense])
      @financial_entries = @financial_entries.where(entry_type: params[:entry_type])
    end

    if params[:category_id].present?
      @financial_entries = @financial_entries.where(category_id: params[:category_id])
    end

    @total_income = @financial_entries.income.sum(:amount)
    @total_expenses = @financial_entries.expense.sum(:amount)
    @categories = current_user.categories
  end

  def new
    @financial_entry = current_user.financial_entries.new(
      date: Date.current,
      entry_type: params[:entry_type] || 'expense'
    )
    @categories = current_user.categories
  end

  def edit
    @categories = current_user.categories
  end

  def create
    @financial_entry = current_user.financial_entries.new(financial_entry_params)
    @categories = current_user.categories

    if @financial_entry.save
      redirect_to financial_entries_path, notice: 'Transação criada com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @categories = current_user.categories
    
    if @financial_entry.update(financial_entry_params)
      redirect_to financial_entries_path, notice: 'Transação atualizada com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @financial_entry.destroy
    redirect_to financial_entries_url, notice: 'Transação excluída com sucesso.'
  end

  private
    def set_financial_entry
      @financial_entry = current_user.financial_entries.find(params[:id])
    end

    def financial_entry_params
      params.require(:financial_entry).permit(:description, :amount, :entry_type, :date, :category_id)
    end
end
