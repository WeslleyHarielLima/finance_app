class AddRecurringToFinancialEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :financial_entries, :recurring, :boolean, default: false
    add_column :financial_entries, :recurring_day, :integer
  end
end
