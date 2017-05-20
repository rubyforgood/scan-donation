class TransactionExport
  def export_to_salesforce(pagination_cursor: nil)
    square_client = ScanDonation.config.square_client

    Rails.logger.info "Starting: Exporting list of transactions from Square."
    results = square_client.list_transactions(pagination_cursor: pagination_cursor)#, begin_time: begin_time)

    Array(results&.transactions).each do |transaction|
      begin
        #TODO: Do the work here.
        #synchronize_square_transaction(transaction)
      rescue => e
        Rails.logger.error(e)
        Rollbar.error(e)
      end
    end

    Rails.logger.info "Finished: Exporting list of transactions from Square."

    if results&.cursor&.present?
      export_to_salesforce(pagination_cursor: results.cursor)
    end
  end

  def begin_time
    5.days.ago
  end
end
