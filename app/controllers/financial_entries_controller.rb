require 'csv'

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

    if params[:search].present?
      @financial_entries = @financial_entries
        .where("description ILIKE ?", "%#{sanitize_sql_like(params[:search])}%")
    end

    @total_income = @financial_entries.income.sum(:amount)
    @total_expenses = @financial_entries.expense.sum(:amount)
    @categories = current_user.categories

    respond_to do |format|
      format.html { @financial_entries = @financial_entries.page(params[:page]).per(20) }
      format.csv { send_data generate_csv(@financial_entries), filename: "transacoes-#{Date.current}.csv" }
      format.pdf { send_data generate_pdf(@financial_entries), filename: "transacoes-#{Date.current}.pdf", type: 'application/pdf' }
    end
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
      redirect_to financial_entries_path, notice: 'Transacao criada com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @categories = current_user.categories

    if @financial_entry.update(financial_entry_params)
      redirect_to financial_entries_path, notice: 'Transacao atualizada com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @financial_entry.destroy
      redirect_to financial_entries_url, notice: 'Transacao excluida com sucesso.'
    else
      redirect_to financial_entries_url, alert: 'Erro ao excluir transacao.'
    end
  end

  private

    def set_financial_entry
      @financial_entry = current_user.financial_entries.find(params[:id])
    end

    def financial_entry_params
      params.require(:financial_entry).permit(:description, :amount, :entry_type, :date, :category_id, :recurring, :recurring_day)
    end

    def sanitize_sql_like(string)
      ActiveRecord::Base.sanitize_sql_like(string)
    end

    def generate_csv(entries)
      CSV.generate(headers: true, col_sep: ';') do |csv|
        csv << ['Data', 'Descricao', 'Categoria', 'Tipo', 'Valor']
        entries.each do |entry|
          csv << [
            entry.date.strftime('%d/%m/%Y'),
            entry.description,
            entry.category&.name,
            entry.income? ? 'Receita' : 'Despesa',
            entry.amount
          ]
        end
      end
    end

    def generate_pdf(entries)
      Prawn::Document.new do |pdf|
        pdf.text "Transacoes Financeiras", size: 20, style: :bold
        pdf.text "Exportado em #{Date.current.strftime('%d/%m/%Y')}", size: 10
        pdf.move_down 20

        data = [['Data', 'Descricao', 'Categoria', 'Tipo', 'Valor (R$)']]
        entries.each do |entry|
          data << [
            entry.date.strftime('%d/%m/%Y'),
            entry.description,
            entry.category&.name || '-',
            entry.income? ? 'Receita' : 'Despesa',
            '%.2f' % entry.amount
          ]
        end

        pdf.table(data, header: true, width: pdf.bounds.width) do
          row(0).font_style = :bold
          row(0).background_color = "DDDDDD"
          columns(4).align = :right
        end
      end.render
    end
end
