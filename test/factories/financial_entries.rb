FactoryBot.define do
  factory :financial_entry do
    user
    description { "Transacao teste" }
    amount { 100.0 }
    entry_type { "expense" }
    date { Date.current }
    recurring { false }

    trait :income do
      entry_type { "income" }
      description { "Receita teste" }
    end

    trait :expense do
      entry_type { "expense" }
      description { "Despesa teste" }
    end

    trait :recurring do
      recurring { true }
      recurring_day { 15 }
    end

    trait :this_month do
      date { Date.current }
    end

    trait :last_month do
      date { 1.month.ago }
    end
  end
end
