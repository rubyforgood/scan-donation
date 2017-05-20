class TransactionExport
  ANONYMOUS_SALESFORCE_CUSTOMER_ID = '00331000031Tt8i'.freeze
  BEGIN_TIME_BUFFER_DAYS = 7.freeze
  VALID_CARD_DETAILS_STATUS = 'CAPTURED'.freeze

  def initialize(now: Time.now)
    @now = now
  end

  def export_to_salesforce(pagination_cursor: nil)
    square_client = ScanDonation.config.square_client

    Rails.logger.info "Starting: Exporting list of transactions from Square."
    begin_time = SquareTransaction.last_written_time || @now
    results = square_client.list_transactions(
      pagination_cursor: pagination_cursor,
      begin_time: BEGIN_TIME_BUFFER_DAYS.days.ago(begin_time)
    )

    Array(results&.transactions).each do |transaction|
      begin
        create_square_transaction(transaction)
      rescue => e
        Rails.logger.error(e)
        Rollbar.error(e)
        raise if Rails.env.test?
      end
    end

    Rails.logger.info "Finished: Exporting list of transactions from Square."

    if results&.cursor&.present?
      export_to_salesforce(pagination_cursor: results.cursor)
    end
  end

  def create_square_transaction(transaction)
    return unless transaction.tenders&.count > 0

    if transaction.tenders.count > 1
      Rollbar.warning("Transaction(#{transaction.id}) has more then one tender.")
    end
    tender      = transaction.tenders.first
    return unless tender&.card_details.status == VALID_CARD_DETAILS_STATUS
    customer_id =
      if tender.customer_id.present?
        #TODO: What if we don't find the customer?
        SquareCustomer.find_by!(square_id: tender.customer_id).salesforce_id
      else
        ANONYMOUS_SALESFORCE_CUSTOMER_ID
      end

    square_transaction = SquareTransaction.find_or_initialize_by(square_id: transaction.id)
    if square_transaction.new_record?
      #salesforce_id = push_donation_to_salesforce(
        #amount:      tender.amount_money,
        #customer_id: customer_id,
        #created_at:  tender.created_at,
      #)
      #TODO: Integrate with salesforce
      salesforce_id = SecureRandom.hex

      square_transaction.salesforce_id = salesforce_id
      square_transaction.save!
    end
  end
end
