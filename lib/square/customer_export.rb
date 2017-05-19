require 'square_connect'

class Square::CustomerExport

  def export_to_salesforce(pagination_cursor: nil)
    salesforce_client = ScanDonation.config.salesforce_client

    Rails.logger.info "Starting: Exporting list of customers from Square."
    results = list(pagination_cursor: pagination_cursor)

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

  def list(pagination_cursor: nil)
    opts = {
      cursor: pagination_cursor
    }

    api_instance.list_customers(auth_token, opts)
  end

  private

  def auth_token
    Square.api_key
  end

  def api_instance
    @api_instance ||= SquareConnect::CustomerApi.new
  end

end
