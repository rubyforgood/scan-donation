class AddCreatedAtIndexOnSquareTransactions < ActiveRecord::Migration[5.1]
  def change
    add_index :square_transactions, :created_at
  end
end
