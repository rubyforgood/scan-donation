require 'test_helper'
require 'minitest/mock'

class TransactionExportTest < ActiveSupport::TestCase
  setup do
    @tenders = [{ customer_id: "321cba", created_at: 5.hours.ago, amount_money: 4200}]
    @response_body = { transactions: [{ id: "abc123", tenders: @tenders, updated_at: 1.day.ago }] }.to_json

    ENV["SALESFORCE_CLIENT_ID"] = 'client_id'
    ENV["SALESFORCE_CLIENT_SECRET"] = 'client_secret'
    ENV["SALESFORCE_USERNAME"] = 'username'
    ENV["SALESFORCE_PASSWORD"] = 'password'
    ENV["SALESFORCE_SECURITY_TOKEN"] = 'security_token'
    ENV["SQUARE_API_KEY"] = 'api_key'

    SquareCustomer.create!(square_id: '321cba', salesforce_id: '42')
  end

  test 'requests transactions from square with no existing synced transactions' do
    skip('unstable in ci')
    now = Time.now.utc
    begin_time = 7.days.ago(now)
    stub_request(:get, "https://connect.squareup.com/v2/locations/FZS7GXYFJ6HRB/transactions?begin_time=#{URI.encode(begin_time.rfc3339)}&sort_order=ASC").
      with(headers: {'Accept'=>'application/json', 'Authorization'=>'Bearer api_key', 'Content-Type'=>'application/json', 'Expect'=>'', 'User-Agent'=>'Square-Connect-Ruby/2.0.2'}).
      to_return(status: 200, body: @response_body, headers: {})

    assert_difference('SquareTransaction.count', 1) do
      TransactionExport.new(now: now).export_to_salesforce
    end
  end

  test 'requests transactios for date from square when synced transactions exist' do
    now = Time.now
    begin_time = 7.days.ago(5.minutes.ago(now))
    SquareTransaction.create!(square_id: '321cba', salesforce_id: '42', created_at: 5.minutes.ago(now))
    stub_request(:get, "https://connect.squareup.com/v2/locations/FZS7GXYFJ6HRB/transactions?begin_time=#{URI.encode(begin_time.utc.rfc3339)}&sort_order=ASC").
      with(headers: {'Accept'=>'application/json', 'Authorization'=>'Bearer api_key', 'Content-Type'=>'application/json', 'Expect'=>'', 'User-Agent'=>'Square-Connect-Ruby/2.0.2'}).
      to_return(status: 200, body: @response_body, headers: {})

    assert_difference('SquareTransaction.count', 1) do
      TransactionExport.new(now: now).export_to_salesforce
    end
  end
end
