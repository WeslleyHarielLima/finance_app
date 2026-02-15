class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable
  
  # Associations
  has_many :financial_entries, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :monthly_budgets, dependent: :destroy
  
  # Validations
  validates :name, presence: true
  validates :monthly_income, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def balance
    financial_entries.income.sum(:amount) - financial_entries.expense.sum(:amount)
  end

  def balance_for_month(date = Date.current)
    range = date.beginning_of_month..date.end_of_month
    entries = financial_entries.where(date: range)
    entries.income.sum(:amount) - entries.expense.sum(:amount)
  end

  def income_for_month(date = Date.current)
    range = date.beginning_of_month..date.end_of_month
    financial_entries.income.where(date: range).sum(:amount)
  end

  def expenses_for_month(date = Date.current)
    range = date.beginning_of_month..date.end_of_month
    financial_entries.expense.where(date: range).sum(:amount)
  end
end
