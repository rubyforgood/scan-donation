require "restforce"

module Salesforce
  class Contact
    attr_reader :first_name, :last_name, :email

    def initialize(first_name:, last_name:, email:)
      @first_name = first_name
      @last_name = last_name
      @email = email
    end

    def to_salesforce
      {
        FirstName: first_name,
        LastName:  last_name,
        Email:     email
      }
    end
  end

  class Client
    API_VERSION = "39.0".freeze
    CONTACT = "Contact".freeze

    def initialize(client_id:, client_secret:, username:, password:, security_token:, logger: Rails.logger)
      @logger = logger

      @client = Restforce.new(
        client_id:      client_id,
        client_secret:  client_secret,
        username:       username,
        password:       password,
        security_token: security_token,
        api_version:    API_VERSION,
        logger:         logger
      )
    end

    def find_contact(first_name: :ignore, last_name: :ignore, nickname: :ignore, email: :ignore)
      clauses = {}
      clauses[:FirstName] = first_name unless first_name == :ignore
      clauses[:LastName] = last_name unless last_name == :ignore
      clauses[:Email] = email unless email == :ignore
      clauses[:Nickname__c] = nickname unless nickname == :ignore

      results = @client.query(
        "SELECT Id FROM #{CONTACT} " +
          "WHERE " + clauses.map { |k, v| "#{k}='#{v}'" }.join(" AND ") + " " + \
          "LIMIT 1"
      )
      results.first&.fetch("Id")
    end

    def create_contact(contact)
      @client.create!(CONTACT, contact.to_salesforce)
    end
  end
end
