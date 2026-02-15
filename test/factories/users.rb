FactoryBot.define do
  factory :user do
    name { "Usuario Teste" }
    sequence(:email) { |n| "usuario#{n}@teste.com" }
    password { "password123" }
    password_confirmation { "password123" }
    confirmed_at { Time.current }
  end
end
