class CreateFinancialEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :financial_entries do |t|
      t.string :description
      t.decimal :amount
      t.string :entry_type
      t.date :date
      t.references :category, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
