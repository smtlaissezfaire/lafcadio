require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/Client'
require 'lafcadio/query/Link'

class TestLinkQuery < LafcadioTestCase
	def testObjectDoesntMeetNil
		link = Query::Link.new 'client', Client.getTestClient, Client
		invoice = Invoice.new ({ 'objId' => 1, 'client' => nil })
		assert !link.objectMeets(invoice)
	end
end