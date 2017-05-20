require 'test_helper'
require 'minitest/mock'

class CustomerExportTest < ActiveSupport::TestCase
  setup do
    @response_body = { customers: [{ id: "abc123", given_name: 'Shrike', family_name: 'Force', updated_at: Time.now.to_s }] }.to_json
    @salesforce_client_mock = Minitest::Mock.new

    ENV["SALESFORCE_CLIENT_ID"] = 'client_id'
    ENV["SALESFORCE_CLIENT_SECRET"] = 'client_secret'
    ENV["SALESFORCE_USERNAME"] = 'username'
    ENV["SALESFORCE_PASSWORD"] = 'password'
    ENV["SALESFORCE_SECURITY_TOKEN"] = 'security_token'
    ENV["SQUARE_API_KEY"] = 'api_key'

    stub_request(:get, "https://connect.squareup.com/v2/customers").
      to_return(status: 200, body: @response_body, headers: {})
  end

  test 'sends customer records to salesforce' do
    @salesforce_client_mock.expect(:synchronize_contact, true, [Salesforce::Contact, Hash])
    ScanDonation.config.stub(:salesforce_client, @salesforce_client_mock) do
      CustomerExport.new.export_to_salesforce
    end
    @salesforce_client_mock.verify
  end
end
