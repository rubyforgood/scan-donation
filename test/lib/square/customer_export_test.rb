require 'test_helper'
require 'square/customer_export'
require 'minitest/mock'

class Square::CustomerExportTest < Minitest::Spec

  describe Square::CustomerExport do
    describe '#export_to_salesforce' do
      let(:response_body) { { customers: [{ given_name: 'Shrike', family_name: 'Force' }] }.to_json }
      let(:salesforce_client_mock) do
        Minitest::Mock.new
      end

      before do
        ENV["SALESFORCE_CLIENT_ID"] = 'client_id'
        ENV["SALESFORCE_CLIENT_SECRET"] = 'client_secret'
        ENV["SALESFORCE_USERNAME"] = 'username'
        ENV["SALESFORCE_PASSWORD"] = 'password'
        ENV["SALESFORCE_SECURITY_TOKEN"] = 'api_token'

        stub_request(:get, "https://connect.squareup.com/v2/customers").
          to_return(status: 200, body: response_body, headers: {})
      end

      it 'sends customer records to salesforce' do
        salesforce_client_mock.expect(:synchronize_contact, true, [Salesforce::Contact, Hash])
        ScanDonation.config.stub(:salesforce_client, salesforce_client_mock) do
          Square::CustomerExport.new.export_to_salesforce
        end
        salesforce_client_mock.verify
      end

    end
  end

end
