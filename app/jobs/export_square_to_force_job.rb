require 'square/customer_export'

class ExportSquareToForceJob < ApplicationJob

  def perform
    CustomerExport.new.export_to_salesforce
  end

end
