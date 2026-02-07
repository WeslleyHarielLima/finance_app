class FinancialEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_financial_entry, only: [:show, :edit, :update, :destroy]

  def index
    @financial_entries = current_user.financial_entries.order(date: :desc)
  end

  def show
  end

  def new
    @financial_entry = current_user.financial_entries.new(date: Date.current)
  end

  def edit
  end

  def create
    @financial_entry = current_user.financial_entries.new(financial_entry_params)

    if @financial_entry.save
      redirect_to financial_entries_path, notice: 'Transação criada com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
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
