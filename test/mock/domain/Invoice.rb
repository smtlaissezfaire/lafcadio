require 'lafcadio/domain'
require 'lafcadio/test'
require 'date'
require '../test/mock/domain'
require '../test/domain/ClassDefinitionXmlParser'

class Invoice < Lafcadio::DomainObject
	include Lafcadio

  def Invoice.getTestInvoice
    hash = { "client" => Client.getTestClient, "rate" => 70,
             "date" => Date.new(2001, 4, 5), "hours" => 36.5, 
						 "invoice_num" => 1, "pk_id" => 1 }
    Invoice.new hash
  end

	def Invoice.storedTestInvoice
		inv = Invoice.getTestInvoice
		inv.client = Client.storedTestClient
		ObjectStore.get_object_store.commit inv
		inv
	end

  def name
    invoice_num.to_s
  end
end
