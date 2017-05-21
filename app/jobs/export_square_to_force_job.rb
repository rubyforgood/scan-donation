class ExportSquareToForceJob < ApplicationJob
  def perform
    CustomerExport.new.export_to_salesforce
    TransactionExport.new.export_to_salesforce
  end
end
