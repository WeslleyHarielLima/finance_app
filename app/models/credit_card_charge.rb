class CreditCardCharge < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true

  validates :description, presence: true, length: { minimum: 2, maximum: 100 }
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  validates :installments, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :start_date, presence: true

  before_save :calculate_installment_amount

  scope :active_in_month, ->(date) {
    month_start = date.beginning_of_month
    where(recurring: true).or(
      where(recurring: [false, nil])
        .where("start_date <= ?", month_start)
        .where(
          "start_date + (installments - 1) * INTERVAL '1 month' >= ?",
          month_start
        )
    )
  }

  scope :installment_charges, -> { where(recurring: [false, nil]).where("installments > 0") }
  scope :recurring_charges, -> { where(recurring: true) }

  def active_in_month?(date)
    month_start = date.beginning_of_month
    return true if recurring?

    start_date <= month_start && end_date >= month_start
  end

  def end_date
    return nil if recurring?

    start_date + (installments - 1).months
  end

  def installment_number_for(date)
    return nil if recurring?

    months_diff = (date.year * 12 + date.month) - (start_date.year * 12 + start_date.month)
    return nil if months_diff < 0 || months_diff >= installments

    months_diff + 1
  end

  def installment_label_for(date)
    return "Recorrente" if recurring?

    number = installment_number_for(date)
    return nil unless number

    "#{number}/#{installments}"
  end

  def paid_off?
    return false if recurring?

    Date.current.beginning_of_month > end_date
  end

  private

  def calculate_installment_amount
    self.installment_amount = (total_amount / installments).round(2) if total_amount && installments && installments > 0
  end
end
