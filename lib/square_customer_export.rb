require 'square_connect'

class SquareCustomerExport

  attr_reader :auth_token

  def initialize(auth_token)
    @auth_token = auth_token
  end

  def list(pagination_cursor: nil)
    #opts = {
    # cursor: pagination_cursor.to_s
    #}
    opts = {}

    api_instance.list_customers(auth_token, opts)
  rescue SquareConnect::ApiError => e
    #TODO: Add Logger?
    puts "Exception when calling CustomerApi->list_customers: #{e}"
  end

  private

  def api_instance
    @api_instance ||= SquareConnect::CustomerApi.new
  end

end
