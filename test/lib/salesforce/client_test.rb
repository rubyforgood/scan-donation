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

    it "creates a contact if one doesn't currently exist" do
      stub_salesforce_login
      stub_salesforce_search(/SELECT.*FROM.*Contact/, [])

      contact = Salesforce::Contact.new(
        first_name: "John",
        last_name:  "Smith",
        email:      "johnsmith@example.com"
      )

      req = stub_request(:post, "#{INSTANCE_URL}/services/data/v#{API_VERSION}/sobjects/Contact")
        .with(body: {
          "FirstName" => contact.first_name,
          "LastName" => contact.last_name,
          "Email" => contact.email
        })
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: JSON.dump(Id: "003abc123")
        )

      client.synchronize_contact(contact)
      assert_requested req
    end

    it "adds an email address to an existing contact if one doesn't exist" do
      stub_salesforce_login
      stub_salesforce_search(/SELECT.*FROM.*Contact/, [
        { "Id" => "abc123", "Email" => nil }
      ])

      contact = Salesforce::Contact.new(
        first_name: "John",
        last_name: "Smith",
        email: "johnsmith@example.com"
      )

      req = stub_request(:patch, "#{INSTANCE_URL}/services/data/v#{API_VERSION}/sobjects/Contact/abc123")
        .with(body: { "Email" => contact.email })
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: JSON.dump(Id: "abc123")
        )

      client.synchronize_contact(contact)
      assert_requested req
    end
  end
end
