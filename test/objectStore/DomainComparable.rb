require 'lafcadio/test/LafcadioTestCase'
require '../test/mock/domain/Client'

class TestDomainComparable < LafcadioTestCase
	def testComparableToNil
		client = Client.storedTestClient
		assert( !( client == nil ) )
	end
end