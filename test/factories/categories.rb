FactoryBot.define do
  factory :category do
    user
    sequence(:name) { |n| "Categoria #{n}" }
    color { "#007bff" }
    icon { "📦" }
  end
end
