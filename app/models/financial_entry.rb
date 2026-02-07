class FinancialEntry < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  
  validates :description, presence: true, length: { minimum: 2, maximum: 100 }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :entry_type, presence: true, inclusion: { in: ['income', 'expense'] }
  validates :date, presence: true
  
  scope :incomes, -> { where(entry_type: 'income') }
  scope :expenses, -> { where(entry_type: 'expense') }
  scope :this_month, -> { 
    where(date: Date.current.beginning_of_month..Date.current.end_of_month) 
  }
  
  def formatted_amount
    "R$ #{'%.2f' % amount}".gsub('.', ',')
  end
  
  def income?
    entry_type == 'income'
  end
  
  def expense?
    entry_type == 'expense'
  end
end
