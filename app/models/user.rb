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
end
