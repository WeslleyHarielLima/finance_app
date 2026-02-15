class ChangeCategoryIdNullableOnFinancialEntries < ActiveRecord::Migration[8.1]
  def change
    change_column_null :financial_entries, :category_id, true
  end
end
