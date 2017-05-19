require 'square_connect'

class Square::CustomerExport

  def export_to_salesforce(pagination_cursor: nil)
    Rails.logger.info "Starting: Exporting list of customers from Square."
    results = list

    Array(results&.customers).each do |customer|
      Salesforce::Client.syncronize_contact(
        Salesforce::Contact.new(
          first_name: customer.given_name,
          last_name:  customer.family_name,
          email:      customer.email_address,
        )
      )
    end

    Rail.logger.info "Finished: Exporting list of customers from Square."

    export_to_salesforce(pagination_cursor: results.cursor) unless resuls.cursor.nil?
  end

  def list(pagination_cursor: nil)
    opts = {
      cursor: pagination_cursor
    }

    api_instance.list_customers(auth_token, opts)
  rescue SquareConnect::ApiError => e
    Rails.logger.error "Exception when calling SquareConnect::CustomerApi->list_customers: #{e}"
    OpenStruct.new
  end

  private

  def auth_token
    Square.api_key
  end

  def api_instance
    @api_instance ||= SquareConnect::CustomerApi.new
  end

end
