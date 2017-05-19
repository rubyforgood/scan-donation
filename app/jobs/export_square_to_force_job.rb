require 'square/customer_export'

class ExportSquareToForceJob < ApplicationJob

  def perform
    Square::CustomerExport.new.export_to_sales_force
  end

end
