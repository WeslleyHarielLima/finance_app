class AddCategoryToFinancialEntries < ActiveRecord::Migration[8.1]
  def change
    add_reference :financial_entries, :category, null: false, foreign_key: true
  end
end
