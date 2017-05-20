class CreateSquareTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :square_transactions do |t|
      t.string :square_id, null: false
      t.string :salesforce_id, null: false

      t.timestamps null: false
    end

    add_index :square_transactions, :square_id, unique: true
  end
end
