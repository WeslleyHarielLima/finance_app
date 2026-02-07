class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  has_many :financial_entries, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :monthly_budgets, dependent: :destroy
end
