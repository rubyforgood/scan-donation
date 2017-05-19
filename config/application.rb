require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ScanDonation
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.autoload_paths << Rails.root.join("lib")
  end

  def self.config
    @config ||= Configuration.new
  end

  class Configuration
    def salesforce_client
      @salesforce_client ||= Salesforce::Client.new(
        client_id:      ENV.fetch("SALESFORCE_CLIENT_ID"),
        client_secret:  ENV.fetch("SALESFORCE_CLIENT_SECRET"),
        username:       ENV.fetch("SALESFORCE_USERNAME"),
        password:       ENV.fetch("SALESFORCE_PASSWORD"),
        security_token: ENV.fetch("SALESFORCE_SECURITY_TOKEN")
      )
    end

    def square_client
      @square_client ||= Square::Client.new(
        api_key: ENV.fetch("SQUARE_API_KEY")
      )
    end
  end
end
