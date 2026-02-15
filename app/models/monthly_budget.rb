class MonthlyBudget < ApplicationRecord
  belongs_to :user

  validates :month, presence: true, uniqueness: { scope: :user_id }
  validates :total_amount, presence: true, numericality: { greater_than: 0 }

  def spent
    user.financial_entries
      .expense
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

  def alert_level
    pct = percentage_used
    case pct
    when 0..70   then :normal
    when 71..90  then :warning
    when 91..100 then :danger
    else              :exceeded
    end
  end

  def alert_message
    case alert_level
    when :warning  then "Voce ja usou #{percentage_used}% do orcamento"
    when :danger   then "Atencao! Voce esta em #{percentage_used}% do orcamento"
    when :exceeded then "Orcamento ultrapassado em R$ #{'%.2f' % remaining.abs}"
    end
  end
end
