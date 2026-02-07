class Category < ApplicationRecord
  belongs_to :user
  has_many :financial_entries, dependent: :nullify
  
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :color, presence: true
  validates :icon, presence: true
end
