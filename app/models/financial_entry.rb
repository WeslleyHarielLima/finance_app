class FinancialEntry < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true

  enum :entry_type, { income: 'income', expense: 'expense' }

  validates :description, presence: true, length: { minimum: 2, maximum: 100 }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :entry_type, presence: true
  validates :date, presence: true

  scope :this_month, -> {
    where(date: Date.current.beginning_of_month..Date.current.end_of_month)
  }
end
