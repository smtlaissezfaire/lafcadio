require 'lafcadio/test'
require '../test/mock/domain'

class TestDomainComparable < LafcadioTestCase
	def testComparableToNil
		client = Client.storedTestClient
		assert( !( client == nil ) )
	end
end