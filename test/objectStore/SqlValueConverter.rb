require '../test/mock/domain/InternalClient'
require '../test/mock/domain/Client'
require '../test/mock/domain/User'
require 'lafcadio/test'
require '../test/mock/domain/Invoice'
require 'lafcadio/objectStore'
require 'dbi'

class TestSqlValueConverter < LafcadioTestCase
  def testExecute
    row_hash = { "id" => "1", "name" => "clientName1",
		"standard_rate" => "70" }
    converter = SqlValueConverter.new(Client, row_hash)
    assert_equal("clientName1", converter["name"])
    assert_equal(70, converter["standard_rate"])
  end

  def testTurnsLinkIdsIntoProxies
    row_hash = { "client" => "1", "date" => DBI::Date.new( 2001, 1, 1 ),
                "rate" => "70", "hours" => "40",
                "paid" => DBI::Date.new( 0, 0, 0 ) }
    converter = SqlValueConverter.new(Invoice, row_hash)
		assert_nil converter['clientId']
		assert_equal DomainObjectProxy, converter['client'].class
		proxy = converter['client']
		assert_equal 1, proxy.pk_id
		assert_equal Client, proxy.object_type
  end

  def testConvertsPkId
    row_hash = { "pk_id" => "1", "name" => "clientName1",
		"standard_rate" => "70" }
    converter = SqlValueConverter.new(Client, row_hash)
    assert_equal(Fixnum, converter["pk_id"].class)
  end

	def testInheritanceConstruction
		row_hash = { 'pk_id' => '1', 'name' => 'clientName1',
				'billingType' => 'trade' }
		objectHash = SqlValueConverter.new(InternalClient, row_hash)
		assert_equal 'clientName1', objectHash['name']
		assert_equal 'trade', objectHash['billingType']
	end
	
	def test_raises_if_bad_primary_key_match
		row_hash = { 'objId' => '1', 'name' => 'client name',
		             'standard_rate' => '70' }
		object_hash = SqlValueConverter.new( Client, row_hash )
		error_msg = 'The field "pk_id" can\'t be found in the table "clients".'
		assert_raise( FieldMatchError, error_msg ) { object_hash['pk_id'] }
	end
	
	def test_different_db_field_name
		string = "Jane says I'm done with Sergio"
		svc = SqlValueConverter.new( XmlSku, { 'text_one' => string } )
		assert_equal( string, svc['text1'] )
	end
end
