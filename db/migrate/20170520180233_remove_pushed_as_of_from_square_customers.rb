class RemovePushedAsOfFromSquareCustomers < ActiveRecord::Migration[5.1]
  def change
    remove_column :square_customers, :pushed_as_of, :string, null: false
  end
end
