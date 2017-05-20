require 'square_connect'

class CustomerExport
  def initialize(salesforce_client: ScanDonation.config.salesforce_client, wet_run: ScanDonation.config.wet_run?)
    @salesforce_client = salesforce_client
    @wet_run = wet_run
  end

  def export_to_salesforce(pagination_cursor: nil)
    square_client = ScanDonation.config.square_client

    Rails.logger.info "Starting: Exporting list of customers from Square."
    results = square_client.list_customers(pagination_cursor: pagination_cursor)

    Array(results&.customers).each do |customer|
      begin
        create_square_customer(customer)
      rescue => e
        Rails.logger.error(e)
        Rollbar.error(e)
        raise if Rails.env.test?
      end
    end

    Rails.logger.info "Finished: Exporting list of customers from Square."

    if results&.cursor&.present?
      export_to_salesforce(pagination_cursor: results.cursor)
    end
  end

  private

  def create_square_customer(customer)
    square_customer = SquareCustomer.find_or_initialize_by(square_id: customer.id)
    if square_customer.new_record?
      salesforce_id = find_square_customer_in_salesforce(customer)
      if salesforce_id.nil? && @wet_run
        salesforce_id = create_square_customer_in_salesforce(customer)
      elsif salesforce_id.nil?
        Rails.logger.info "Dry run: would create #{customer} in Salesforce"
      end

      if !salesforce_id.nil?
        square_customer.salesforce_id = salesforce_id
        square_customer.save!
      end
    end
  end

  def find_square_customer_in_salesforce(customer)
    # Match on first name, last name, and email
    if customer.given_name.present? && customer.family_name.present? && customer.email_address.present?
      id = @salesforce_client.find_contact(
        first_name: customer.given_name,
        last_name:  customer.family_name,
        email:      customer.email_address
      )
      return id if id.present?
    end

    # Fall back to first name and last name
    if customer.given_name.present? && customer.family_name.present?
      id = @salesforce_client.find_contact(
        first_name: customer.given_name,
        last_name:  customer.family_name,
      )
      return id if id.present?
    end

    # Fall back to email
    if customer.email_address.present?
      id = @salesforce_client.find_contact(
        email: customer.email_address
      )
      return id if id.present?
    end

    nil
  end

  def create_square_customer_in_salesforce(customer)
    @salesforce_client.create_contact(
      Salesforce::Contact.new(
        first_name: customer.given_name.presence || "Unknown",
        last_name:  customer.family_name.presence || "Unknown",
        email:      customer.email_address.presence
      )
    )
  end
end
