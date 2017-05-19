require "restforce"

module Salesforce
  class Contact
    attr_reader :first_name, :last_name, :email

    def initialize(first_name:, last_name:, email:)
      @first_name = first_name
      @last_name = last_name
      @email = email
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

    def synchronize_contact(contact, dry_run: false)
      results = @client.query(
        format(
          "SELECT Id, Email FROM %s " + \
            "WHERE FirstName = '%s' AND " + \
            "LastName = '%s' AND " + \
            "IsDeleted = false " + \
            "LIMIT 1",
          CONTACT,
          contact.first_name,
          contact.last_name
        )
      )

      result = results.first
      if result
        # An existing contact exists
        fields = {}

        # TODO: Should we overwrite email if it already exists?
        if !result["Email"].present?
          fields["Email"] = contact.email
        end

        if fields.any?
          if dry_run
            @logger.info("Would update #{CONTACT} with Id: #{result["Id"]}: #{fields.inspect}")
          else
            @client.update!(CONTACT, fields.merge(Id: result["Id"]))
          end
        elsif dry_run
          @logger.info("No fields to update for #{CONTACT} with Id #{result["Id"]}")
        end
      else
        fields = {
          FirstName: contact.first_name,
          LastName:  contact.last_name,
          Email:     contact.email
        }

        if dry_run
          @logger.info("Would create #{CONTACT}: #{fields.inspect}")
        else
          @client.create!(CONTACT, fields)
        end
      end
    end
  end
end
