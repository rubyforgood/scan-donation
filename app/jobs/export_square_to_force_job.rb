require 'square/customer_export'

class ExportSquareToForce < ApplicationJob

  def perform
    export  = Square::CustomerExport.new
    results = export.list

    Array(results&.customers).each do |customer|
      Salesforce::Client.syncronize_contact(
        Salesforce::Contact.new(
          first_name: customer.given_name,
          last_name:  customer.family_name,
          email:      customer.email_address,
        )
      )
    end

  end

end
