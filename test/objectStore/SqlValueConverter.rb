require '../test/mock/domain/InternalClient'
require '../test/mock/domain/Client'
require '../test/mock/domain/User'
require 'lafcadio/test/LafcadioTestCase'
require '../test/mock/domain/Invoice'
require 'lafcadio/objectStore/SqlValueConverter'
require 'dbi'

class TestSqlValueConverter < LafcadioTestCase
  def testExecute
    rowHash = { "id" => "1", "name" => "clientName1",
		"standard_rate" => "70" }
    converter = SqlValueConverter.new(Client, rowHash)
    assert_equal("clientName1", converter["name"])
    assert_equal(70, converter["standard_rate"])
  end

  def testTurnsLinkIdsIntoProxies
    rowHash = { "client" => "1", "date" => DBI::Date.new( 2001, 1, 1 ),
                "rate" => "70", "hours" => "40",
                "paid" => DBI::Date.new( 0, 0, 0 ) }
    converter = SqlValueConverter.new(Invoice, rowHash)
		assert_nil converter['clientId']
		assert_equal DomainObjectProxy, converter['client'].class
		proxy = converter['client']
		assert_equal 1, proxy.pkId
		assert_equal Client, proxy.objectType
  end

  def testConvertsPkId
    rowHash = { "pkId" => "1", "name" => "clientName1",
		"standard_rate" => "70" }
    converter = SqlValueConverter.new(Client, rowHash)
    assert_equal(Fixnum, converter["pkId"].class)
  end

	def testInheritanceConstruction
		rowHash = { 'pkId' => '1', 'name' => 'clientName1',
				'billingType' => 'trade' }
		objectHash = SqlValueConverter.new(InternalClient, rowHash)
		assert_equal 'clientName1', objectHash['name']
		assert_equal 'trade', objectHash['billingType']
	end
end
