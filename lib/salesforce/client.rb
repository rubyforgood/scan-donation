require "restforce"

module Salesforce
  class Account
    attr_reader :id, :name

    def initialize(id:, name:)
      @id = id
      @name = name
    end
  end

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

  class Donation
    RECORD_TYPE_ID = "012i0000000hSyeAAE".freeze
    PRIMARY_CAMPAIGN_SOURCE_ID = "70131000001mkhB".freeze

    attr_reader :account_id, :account_name, :contact_id, :close_date, :amount

    def initialize(account_id:, account_name:, contact_id:, close_date:, amount:)
      @account_id = account_id
      @account_name = account_name
      @contact_id = contact_id
      @close_date = close_date
      @amount = amount
    end

    def name
      "#{account_name} $#{amount} Donation #{close_date.strftime("%m/%d/%Y")}"
    end

    def to_salesforce
      {
        RecordTypeId:             RECORD_TYPE_ID,
        CampaignId:               PRIMARY_CAMPAIGN_SOURCE_ID,
        Name:                     name,
        AccountId:                account_id,
        npsp__Primary_Contact__c: contact_id,
        StageName:                "Posted",
        CloseDate:                close_date.iso8601,
        Type:                     "Individual",
        Amount:                   amount
      }
    end
  end

  class Client
    API_VERSION = "39.0".freeze

    CONTACT = "Contact".freeze
    OPPORTUNITY = "Opportunity".freeze

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

    def account_for_contact(contact_id)
      results = @client.query(
        "SELECT Account.Id, Account.Name FROM #{CONTACT} WHERE Id='%s'" % [contact_id]
      )

      result = results.first
      if result.present?
        Account.new(
          id:   result["Account"]["Id"],
          name: result["Account"]["Name"]
        )
      end
    end

    def create_contact(contact)
      @client.create!(CONTACT, contact.to_salesforce)
    end

    def create_donation(donation)
      @client.create!(OPPORTUNITY, donation.to_salesforce)
    end
  end
end
