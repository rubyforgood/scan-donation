require 'square/customer_export'

class ExportSquareToForce < ApplicationJob

  def perform
    Square::CustomerExport.new.export_to_sales_force
  end

end
