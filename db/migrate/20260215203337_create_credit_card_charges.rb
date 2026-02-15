class CreateCreditCardCharges < ActiveRecord::Migration[8.1]
  def change
    create_table :credit_card_charges do |t|
      t.string :description, null: false
      t.decimal :total_amount, null: false
      t.integer :installments, null: false, default: 1
      t.decimal :installment_amount, null: false
      t.date :start_date, null: false
      t.boolean :recurring, default: false
      t.references :category, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :credit_card_charges, [:user_id, :start_date]
  end
end
