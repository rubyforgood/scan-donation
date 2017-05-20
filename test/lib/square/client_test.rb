require 'test_helper'
require 'square/client'

module Square
  class ClientTest < Minitest::Spec

    describe Square::Client do
      let(:api_key) { SecureRandom.base64 }
      let(:client)  { Square::Client.new(api_key: api_key) }
      let(:response_body) { { customers: [{ given_name: 'Shrike', family_name: 'Force' }] }.to_json }

      before do
        stub_request(:get, "https://connect.squareup.com/v2/customers").
          with(headers: {'Accept'=>'application/json', 'Authorization'=>"Bearer #{api_key}", 'Content-Type'=>'application/json', 'Expect'=>'', 'User-Agent'=>'Square-Connect-Ruby/2.0.2'}).
          to_return(status: 200, body: response_body, headers: {})
      end

      describe '#list_customers' do
        it 'lists the customers' do
          customers = client.list_customers&.customers
          assert_equal(1, customers.count)
          customer = customers.first
          assert_equal('Shrike', customer.given_name)
          assert_equal('Force', customer.family_name)
        end
      end
    end

  end
end
