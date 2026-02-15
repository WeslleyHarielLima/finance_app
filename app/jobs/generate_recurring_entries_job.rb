class GenerateRecurringEntriesJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      FinancialEntry.generate_recurring_for_month(user)
    end
  end
end
