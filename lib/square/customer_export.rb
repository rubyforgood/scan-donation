require 'square_connect'

class Square::CustomerExport

  def export_to_salesforce(pagination_cursor: nil)
    salesforce_client = ScanDonation.config.salesforce_client
    square_client     = ScanDonation.config.square_client

    Rails.logger.info "Starting: Exporting list of customers from Square."
    results = square_client.list_customers(pagination_cursor: pagination_cursor)

    Array(results&.customers).each do |customer|
      salesforce_client.synchronize_contact(
        Salesforce::Contact.new(
          first_name: customer.given_name,
          last_name:  customer.family_name,
          email:      customer.email_address,
        ),
        dry_run: true
      )
    end

    Rails.logger.info "Finished: Exporting list of customers from Square."

    if results&.cursor&.present?
      export_to_salesforce(pagination_cursor: results.cursor)
    end
  end

  private

  def auth_token
    Square.api_key
  end

end
