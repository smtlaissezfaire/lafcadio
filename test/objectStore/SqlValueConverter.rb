require 'test/mock/domain/InternalClient'
require 'test/mock/domain/Client'
require 'test/mock/domain/User'
require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/Invoice'
require 'lafcadio/objectStore/SqlValueConverter'

class TestSqlValueConverter < LafcadioTestCase
  def testExecute
    rowHash = { "id" => "1", "name" => "clientName1",
		"standard_rate" => "70" }
    converter = SqlValueConverter.new (Client, rowHash)
    objectHash = converter.execute
    assert_equal("clientName1", objectHash["name"])
    assert_equal(70, objectHash["standard_rate"])
  end

  def testTurnsLinkIdsIntoProxies
    rowHash = { "client" => "1", "date" => "2001-01-01", "rate" => "70",
		"hours" => "40", "paid" => "0000-00-00" }
    converter = SqlValueConverter.new (Invoice, rowHash)
    objectHash = converter.execute
		assert_nil objectHash['clientId']
		assert_equal DomainObjectProxy, objectHash['client'].type
		proxy = objectHash['client']
		assert_equal 1, proxy.objId
		assert_equal Client, proxy.objectType
  end

  def testConvertsObjId
    rowHash = { "objId" => "1", "name" => "clientName1",
		"standard_rate" => "70" }
    converter = SqlValueConverter.new (Client, rowHash)
    objectHash = converter.execute
    assert_equal (Fixnum, objectHash["objId"].type)
  end

	def testInheritanceConstruction
		rowHash = { 'objId' => '1', 'name' => 'clientName1',
				'billingType' => 'trade' }
		objectHash = SqlValueConverter.new(InternalClient, rowHash).execute
		assert_equal 'clientName1', objectHash['name']
		assert_equal 'trade', objectHash['billingType']
	end
end
