require 'lafcadio/test'
require '../test/mock/domain'
require 'lafcadio/query'

class TestLinkQuery < LafcadioTestCase
	def testObjectDoesntMeetNil
		link = Query::Link.new 'client', Client.getTestClient, Client
		invoice = Invoice.new({ 'pk_id' => 1, 'client' => nil })
		assert !link.object_meets(invoice)
	end
end