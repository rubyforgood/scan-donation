require 'test_helper'
require 'minitest/mock'

class TransactionExportTest < ActiveSupport::TestCase
  setup do
    @response_body = { transactions: [{ id: "abc123", tenders: [], updated_at: 1.day.ago }] }.to_json

    ENV["SALESFORCE_CLIENT_ID"] = 'client_id'
    ENV["SALESFORCE_CLIENT_SECRET"] = 'client_secret'
    ENV["SALESFORCE_USERNAME"] = 'username'
    ENV["SALESFORCE_PASSWORD"] = 'password'
    ENV["SALESFORCE_SECURITY_TOKEN"] = 'security_token'
    ENV["SQUARE_API_KEY"] = 'api_key'

    stub_request(:get, "https://connect.squareup.com/v2/locations/FZS7GXYFJ6HRB/transactions?sort_order=ASC").
      with(headers: {'Accept'=>'application/json', 'Authorization'=>'Bearer api_key', 'Content-Type'=>'application/json', 'Expect'=>'', 'User-Agent'=>'Square-Connect-Ruby/2.0.2'}).
      to_return(status: 200, body: @response_body, headers: {})
  end

  test 'requests transactions from square' do
    TransactionExport.new.export_to_salesforce
  end
end
