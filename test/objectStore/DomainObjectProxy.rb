require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/Invoice'
require 'test/mock/domain/Client'

class TestDomainObjectProxy < LafcadioTestCase
	def setup
		super
		@client = Client.storedTestClient
		@clientProxy = DomainObjectProxy.new(Client, 1)
		@clientProxy2 = DomainObjectProxy.new(Client, 2)
		@invoice = Invoice.storedTestInvoice
		@invoiceProxy = DomainObjectProxy.new(Invoice, 1)
	end

	def testComparisons
		assert @clientProxy == @client
		assert @client == @clientProxy
		assert @clientProxy < @clientProxy2
		assert @client < @clientProxy2
		assert @clientProxy != @invoiceProxy
	end

	def testMemberMethods
		assert_equal @client.name, @clientProxy.name
		assert_equal @invoice.name, @invoiceProxy.name
	end

	def testInitFromDbObject
		clientProxyPrime = DomainObjectProxy.new(@client)
		assert @clientProxy == clientProxyPrime
	end

	def testGetDbObject
		assert_equal @client, @clientProxy.getDbObject
		begin
			@clientProxy2.getDbObject
			fail "should throw DomainObjectNotFoundError"
		rescue DomainObjectNotFoundError
			# ok
		end
	end

	def testEqlAndHash
		assert (@client.eql? (@clientProxy))
		assert (@clientProxy.eql? (@client))
		assert_equal(@mockObjectStore.getClient(1).hash, @clientProxy.hash)
	end
end