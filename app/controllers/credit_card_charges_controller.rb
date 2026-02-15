class CreditCardChargesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_charge, only: [:edit, :update, :destroy]

  def index
    @charges = current_user.credit_card_charges
      .includes(:category)
      .order(start_date: :desc, created_at: :desc)

    @active_charges = @charges.select { |c| !c.paid_off? }
    @paid_off_charges = @charges.select { |c| c.paid_off? }
    @categories = current_user.categories
  end

  def new
    @charge = current_user.credit_card_charges.new(
      start_date: Date.current,
      installments: 1
    )
    @categories = current_user.categories
  end

  def edit
    @categories = current_user.categories
  end

  def create
    @charge = current_user.credit_card_charges.new(charge_params)
    @categories = current_user.categories

    if @charge.save
      redirect_to credit_card_charges_path, notice: 'Gasto do cartao criado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @categories = current_user.categories

    if @charge.update(charge_params)
      redirect_to credit_card_charges_path, notice: 'Gasto do cartao atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @charge.destroy
    redirect_to credit_card_charges_path, notice: 'Gasto do cartao excluido com sucesso.'
  end

  private

  def set_charge
    @charge = current_user.credit_card_charges.find(params[:id])
  end

  def charge_params
    params.require(:credit_card_charge).permit(
      :description, :total_amount, :installments, :start_date, :category_id, :recurring
    )
  end
end
