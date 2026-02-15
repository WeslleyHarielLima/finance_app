class MonthlyBudget < ApplicationRecord
  belongs_to :user

  validates :month, presence: true, uniqueness: { scope: :user_id }
  validates :total_amount, presence: true, numericality: { greater_than: 0 }

  def spent
    user.financial_entries
      .expenses
      .where(date: month.beginning_of_month..month.end_of_month)
      .sum(:amount)
  end

  def remaining
    total_amount - spent
  end

  def percentage_used
    return 0 if total_amount.zero?
    ((spent / total_amount) * 100).round(1)
  end

  def exceeded?
    spent > total_amount
  end
end
