class TransactionExport
  ANONYMOUS_SALESFORCE_CONTACT_ID = '00331000031Tt8i'.freeze
  BEGIN_TIME_BUFFER_DAYS = 7.freeze
  CARD_STATUS_CAPTURED = 'CAPTURED'.freeze

  def initialize(salesforce_client: ScanDonation.config.salesforce_client,
                 wet_run: ScanDonation.config.wet_run?,
                 now: Time.now)
    @salesforce_client = salesforce_client
    @wet_run = wet_run
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

  private

  def create_square_transaction(transaction)
    return unless transaction.tenders&.count > 0

    if transaction.tenders.count > 1
      Rollbar.warning("Transaction #{transaction} has more then one tender.")
    end

    tender = transaction.tenders.first
    if tender&.card_details.status != CARD_STATUS_CAPTURED
      Rails.logger.debug("Transaction #{transaction} is not #{CARD_STATUS_CAPTURED}. Skipping")
      return
    end

    contact_id = \
      if tender.customer_id.present?
        # TODO: What if we don't find the customer? For now, raise an error so
        # we can know this actually happens.
        SquareCustomer.find_by!(square_id: tender.customer_id).salesforce_id
      else
        ANONYMOUS_SALESFORCE_CONTACT_ID
      end

    square_transaction = SquareTransaction.find_or_initialize_by(square_id: transaction.id)
    if square_transaction.new_record?
      account = @salesforce_client.account_for_contact(contact_id)
      if account.nil?
        Rails.logger.error("No Salesforce Account found for Contact #{contact_id}. Transaction cannot be created.")
        return
      end

      if @wet_run
        square_transaction.salesforce_id = @salesforce_client.create_donation(
          Salesforce::Donation.new(
            account_id:   account.id,
            account_name: account.name,
            contact_id:   contact_id,
            close_date:   Time.parse(tender.created_at),
            amount:       (BigDecimal(tender.amount_money.amount) / 100).to_s
          )
        )
        square_transaction.save!
      else
        Rails.logger.info "Dry run: would create #{transaction} in Salesforce"
      end
    else
      Rails.logger.debug "Transaction #{transaction} already present in Salesforce. Skipping."
    end
  end
end
