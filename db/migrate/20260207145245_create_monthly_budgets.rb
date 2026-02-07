class CreateMonthlyBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :monthly_budgets do |t|
      t.date :month
      t.decimal :total_amount
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
