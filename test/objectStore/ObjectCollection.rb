require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/Invoice'
require 'test/mock/domain/Client'
require 'test/mock/domain/User'

class TestObjectCollection < LafcadioTestCase
  def setup
		super
    @objColl = Collection.new Invoice
    @invoice = Invoice.storedTestInvoice
    @objColl << @invoice
    @clientColl = Collection.new Client
    @client3 = Client.new( { "objId" => 1, "name" => "ClientName3" } )
    @client1 = Client.new( { "objId" => 2, "name" => "clientName1" } )
    @client4 = Client.new( { "objId" => 3, "name" => "clientnm4" } )
		@clientColl << @client3
		@clientColl << @client1
		@clientColl << @client4
  end

  def testFilterObjects
    assert_equal(1, @objColl.size)
		assert_not_nil @invoice.client
    filtered = @objColl.filterObjects("client", @invoice.client)
    assert_equal(1, filtered.size)
    client2 = Client.new ( { "name" => "clientName2" } )
    filtered2 = @objColl.filterObjects("client", client2)
    assert_equal(0, filtered2.size)
  end

  def testGetObjectCollection
    oc = Collection.new User
    assert_equal(Collection, oc.type)
  end

	def testSort
		assert @clientColl.index(@client1) > @clientColl.index(@client3)
		otherClientColl = @clientColl.sort( ["name"] )
		assert otherClientColl.index(@client1) < otherClientColl.index(@client3)
		@clientColl.sort! ([ "name" ])
		assert @clientColl.index(@client1) < @clientColl.index(@client3)
	end

	def testMultiValSort
		newClientColl = Collection.new Client
		newClientColl << (Client.new ({ 'objId' => 10, 'name' => 'name' }))
		newClientColl << (Client.new ({ 'objId' => 1, 'name' => 'name' }))
		assert_equal 10, newClientColl[0].objId
		newClientColl.sort! ([ 'name', 'objId' ])
		assert_equal 1, newClientColl[0].objId
	end

	def testSortBlock
		assert @clientColl.index(@client1) > @clientColl.index(@client3)
		otherClientColl = @clientColl.sort { |x,y|
			x.name.upcase <=> y.name.upcase
		}
		assert otherClientColl.index(@client1) < otherClientColl.index(@client3)
		@clientColl.sort! { |x,y| x.name.upcase <=> y.name.upcase }
		assert @clientColl.index(@client1) < @clientColl.index(@client3)
	end

  def testRemoveObjects
    newColl = @objColl.removeObjects("invoice_num", 1)
    assert_equal 0, newColl.size
  end

  def testFilterByBlock
    newColl = @clientColl.filterByBlock { |obj| obj.objId%2 == 0 }
    assert_equal 1, newColl.size
  end

	def testOnlyStoreDBObjects
		caught = false
		begin
			Collection.new Array
		rescue
			caught = true
		end
		assert caught
	end
end