module Square
  class Client
    attr_reader :api_key

    LOCATION_ID = "FZS7GXYFJ6HRB".freeze

    def initialize(api_key:)
      @api_key = api_key
    end

    def list_customers(pagination_cursor: nil)
      square_client = SquareConnect::CustomerApi.new
      square_client.list_customers(api_key, cursor: pagination_cursor)
    end

    def list_transactions(pagination_cursor: nil, begin_time: nil)
      square_client = SquareConnect::TransactionApi.new

      opts = {
        begin_time: begin_time&.rfc3339,
        sort_order: "ASC",
        cursor:     pagination_cursor,
      }

      square_client.list_transactions(api_key, LOCATION_ID, opts)
    end

  end
end
