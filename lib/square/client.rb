module Square
  class Client
    attr_reader :api_key, :square_client

    def initialize(api_key:)
      @api_key = api_key
      @square_client = SquareConnect::CustomerApi.new
    end

    def list_customers(pagination_cursor: nil)
      square_client.list_customers(api_key, cursor: pagination_cursor)
    end

  end
end
