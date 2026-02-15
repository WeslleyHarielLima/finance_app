class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :financial_entries, [:user_id, :date]
    add_index :financial_entries, [:user_id, :entry_type]
    add_index :financial_entries, [:user_id, :entry_type, :date]
    add_index :monthly_budgets,  [:user_id, :month], unique: true
    add_index :categories,       [:user_id, :name],  unique: true
  end
end
