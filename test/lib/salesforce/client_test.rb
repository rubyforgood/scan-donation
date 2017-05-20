require "test_helper"
require "minitest/spec"
require "salesforce/client"

module Salesforce
  class ClientTest < Minitest::Spec
    INSTANCE_URL = "https://salesforce.example.com".freeze
    API_VERSION = "39.0".freeze

    def stub_salesforce_login
      stub_request(:post, "https://login.salesforce.com/services/oauth2/token")
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: JSON.dump(
            instance_url: INSTANCE_URL,
            access_token: "abc123"
          )
        )
    end

    def stub_salesforce_search(qr, results)
      stub_request(:get, %r{#{Regexp.escape(INSTANCE_URL)}/services/data/v#{Regexp.escape(API_VERSION)}/query\?q=#{qr.source}})
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: JSON.dump(results)
        )
    end

    def client
      @client ||= Salesforce::Client.new(
        client_id:      "client_id",
        client_secret:  "client_secret",
        username:       "username",
        password:       "password",
        security_token: "security_token"
      )
    end

    it "detects whether a contacts exists by querying salesforce" do
      stub_salesforce_login
      stub_salesforce_search(/SELECT.+FROM.+Contact.+WHERE.+FirstName='John'.+AND.+LastName='Smith'/, [{ Id: "abc123" }])

      res = client.find_contact(first_name: "John", last_name: "Smith")
      res.must_equal "abc123"
    end

    it "creates a contact" do
      stub_salesforce_login

      contact = Salesforce::Contact.new(
        first_name: "John",
        last_name:  "Smith",
        email:      "jsmith@example.com"
      )

      stub_request(:post, "#{INSTANCE_URL}/services/data/v#{API_VERSION}/sobjects/Contact")
        .with(body: {FirstName: contact.first_name, LastName: contact.last_name, Email: contact.email})
        .to_return(status: 200, headers: { "content-type" => "application/json" }, body: JSON.dump({ "id" => "abc123"}))

      res = client.create_contact(contact)
      res.must_equal "abc123"
    end

    it "fetches the account associated with a contact by id" do
      stub_salesforce_login
      stub_salesforce_search(/SELECT.+Account\.Id.+FROM.+Contact.+WHERE.+Id='abc123'/, [{ Account: { Id: "zzz999", Name: "account name" } }])

      res = client.account_for_contact("abc123")
      res.id.must_equal "zzz999"
      res.name.must_equal "account name"
    end
  end
end
