require 'lafcadio/domain/DomainObject'
require 'lafcadio/test/LafcadioTestCase'
require 'date'
require 'test/mock/domain/Client'

class Invoice < DomainObject
  def Invoice.getTestInvoice
    hash = { "client" => Client.getTestClient, "rate" => 70,
             "date" => Date.new(2001, 4, 5), "hours" => 36.5, 
						 "invoice_num" => 1, "objId" => 1 }
    Invoice.new hash
  end

	def Invoice.storedTestInvoice
		inv = Invoice.getTestInvoice
		inv.client = Client.storedTestClient
		Context.instance.getObjectStore.addObject inv
		inv
	end

  def Invoice.classFields
		require 'lafcadio/objectField/LinkField'
		require 'lafcadio/objectField/DateField'
		require 'lafcadio/objectField/MoneyField'
		require 'lafcadio/objectField/DecimalField'
		require 'lafcadio/objectField/AutoIncrementField'
		require 'test/mock/domain/Client'
    invoiceNumField = AutoIncrementField.new(Invoice, "invoice_num",
	"Invoice No.")
    clientField = LinkField.new Invoice, Client
    dateField = DateField.new Invoice
    rateField = MoneyField.new Invoice, "rate"
    rateField.setDefault(clientField, "standard_rate")
    hoursField = DecimalField.new (Invoice, "hours", 2)
    paidField = DateField.new (Invoice, "paid", "Paid")
    paidField.notNull = false
    [ invoiceNumField, clientField, dateField, rateField, hoursField,
      paidField ]
  end

  def name
    invoice_num.to_s
  end
end
