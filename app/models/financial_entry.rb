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
  scope :recurring, -> { where(recurring: true) }

  def self.generate_recurring_for_month(user, date = Date.current)
    user.financial_entries.recurring.find_each do |entry|
      day = [entry.recurring_day, date.end_of_month.day].min
      target_date = date.beginning_of_month + (day - 1).days
      unless user.financial_entries.exists?(
        description: entry.description,
        date: date.beginning_of_month..date.end_of_month,
        recurring: false
      )
        user.financial_entries.create!(
          description: entry.description,
          amount: entry.amount,
          entry_type: entry.entry_type,
          category: entry.category,
          date: target_date,
          recurring: false
        )
      end
    end
  end
end
