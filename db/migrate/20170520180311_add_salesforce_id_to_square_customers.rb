class AddSalesforceIdToSquareCustomers < ActiveRecord::Migration[5.1]
  def change
    add_column :square_customers, :salesforce_id, :string, null: false
  end
end
