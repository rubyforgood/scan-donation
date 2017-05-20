class CreateSquareCustomers < ActiveRecord::Migration[5.1]
  def change
    create_table :square_customers do |t|
      t.string :square_id, null: false
      t.datetime :pushed_as_of, null: false

      t.timestamps null: false
    end

    add_index :square_customers, :square_id, unique: true
  end
end
