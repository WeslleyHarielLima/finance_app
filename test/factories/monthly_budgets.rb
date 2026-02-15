FactoryBot.define do
  factory :monthly_budget do
    user
    month { Date.current.beginning_of_month }
    total_amount { 2000.0 }
  end
end
