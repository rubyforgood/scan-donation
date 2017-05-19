require 'square_connect'

class Square::CustomerExport

  def list(pagination_cursor: nil)
    opts = {
      cursor: pagination_cursor
    }

    api_instance.list_customers(auth_token, opts)
  rescue SquareConnect::ApiError => e
    #TODO: Add Logger?
    puts "Exception when calling CustomerApi->list_customers: #{e}"
    OpenStruct.new
  end

  private

  def auth_token
    Square.api_key
  end

  def api_instance
    @api_instance ||= SquareConnect::CustomerApi.new
  end

end
