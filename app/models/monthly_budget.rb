class MonthlyBudget < ApplicationRecord
  belongs_to :user
  
  validates :month, presence: true, uniqueness: { scope: :user_id }
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
end
