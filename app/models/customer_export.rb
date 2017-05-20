require 'square_connect'

class CustomerExport

  def salesforce_client
    @sf_client ||= ScanDonation.config.salesforce_client
  end

  def export_to_salesforce(pagination_cursor: nil)
    square_client = ScanDonation.config.square_client

    Rails.logger.info "Starting: Exporting list of customers from Square."
    results = square_client.list_customers(pagination_cursor: pagination_cursor)

    Array(results&.customers).each do |customer|
      begin
        synchronize_square_customer(customer)
      rescue => e
        Rails.logger.error(e)
        Rollbar.error(e)
      end
    end

    Rails.logger.info "Finished: Exporting list of customers from Square."

    if results&.cursor&.present?
      export_to_salesforce(pagination_cursor: results.cursor)
    end
  end

  def synchronize_square_customer(customer)
    square_customer = SquareCustomer.find_or_initialize_by(square_id: customer.id)
    if square_customer.new_record?
      push_customer_to_salesforce(customer)

      square_customer.pushed_as_of = customer.updated_at
      square_customer.save!
    end
  end

  def push_customer_to_salesforce(customer)
    salesforce_client.synchronize_contact(
      Salesforce::Contact.new(
        first_name: customer.given_name,
        last_name:  customer.family_name,
        email:      customer.email_address,
      ),
      dry_run: true
    )
  end
end
