require '../test/mock/domain/InternalClient'
require "runit/testcase"
require '../test/mock/domain/Client'
require '../test/mock/domain/LineItem'
require 'lafcadio/query'

class TestDBBridge < RUNIT::TestCase
	include Lafcadio

  class MockDbh
  	@@connected = false
  
    attr_reader :lastSQL, :sql_statements
    
		def initialize
			@sql_statements = []
			@@connected = true
		end
		
		def do( sql, *binds )
			logSql( sql )
		end
		
		def logSql( sql )
      @lastSQL = sql
			@sql_statements << sql
		end

    def select_all(str)
			logSql( str )
      if str == "select last_insert_id()"
				[ { 'last_insert_id()' => '12' } ]
			elsif str == 'select max(pk_id) from clients'
				[ [ '1' ] ]
			elsif str == 'select max(date) from invoices'
				[ [ DBI::Date.new( 2001, 4, 5 ) ] ]
			elsif str == 'select * from some_other_table'
				[ OneTimeAccessHash.new( 'some_other_id' => '16',
				                         'text_one' => 'foobar', 'link1' => '1' ) ]
			elsif str == 'select max(some_other_id) from some_other_table'
				[ [ '5' ] ]
			else
				[]
      end
    end

    def get_all(object_type); []; end
    
    def disconnect
    	@@connected = false
    end
    
    def connected?
    	@@connected
    end
  end

	class OneTimeAccessHash < DelegateClass( Hash )
		attr_reader :key_lookups
	
		def initialize( hash )
			super( hash )
			@key_lookups = Hash.new( 0 )
		end
		
		def []( key )
			@key_lookups[key] += 1
			raise "Should only access #{ key } once" if @key_lookups[key] > 1
			super( key )
		end
	end

  def setup
		LafcadioConfig.set_filename 'lafcadio/test/testconfig.dat'
    @mockDbh = MockDbh.new
		DbConnection.set_dbh( @mockDbh )
		@dbb = DbBridge.new
    @client = Client.new( {"pk_id" => 1, "name" => "clientName1"} )
  end

  def teardown
		@dbb = nil
 		DbConnection.flush
		DbConnection.set_db_name nil
	end

  def test_commits_delete
    @client.delete = true
    @dbb.commit(@client)
    assert_equal("delete from clients where pk_id=1", @mockDbh.lastSQL)
  end

  def testCommitsEdit
    @dbb.commit(@client)
    sql = @mockDbh.lastSQL
    assert(sql.index("update clients set name='clientName1'") != nil, sql)
  end
	
	def test_passes_sql_value_converter_to_domain_class_init
		query = Query.new( XmlSku )
		xml_sku = @dbb.get_collection_by_query( query ).only
		assert_equal( 'foobar', xml_sku.text1 )
		assert_equal( 'foobar', xml_sku.text1 )
		assert_nil( xml_sku.date1 )
		assert_nil( xml_sku.date1 )
		assert_equal( DomainObjectProxy, xml_sku.link1.class )
		assert_equal( 1, xml_sku.link1.pk_id )
	end

  def testLastPkIdInserted
    client = Client.new( { "name" => "clientName1" } )
    @dbb.commit client
    assert_equal 12, @dbb.last_pk_id_inserted
    DbConnection.flush
    DbConnection.set_dbh( @mockDbh )
		dbb2 = DbBridge.new
    assert_equal 12, dbb2.last_pk_id_inserted
  end

	def testGetAll
		query = Query.new Domain::LineItem
		coll = @dbb.get_collection_by_query query
		assert_equal Array, coll.class
	end

	def testCommitsForInheritedObjects
		ic = InternalClient.new({ 'pk_id' => 1, 'name' => 'client name',
				'billingType' => 'trade' })
		@dbb.commit ic
		assert_equal 2, @mockDbh.sql_statements.size
		sql1 = @mockDbh.sql_statements[0]
		assert_not_nil sql1 =~ /update clients set/, sql1
		sql2 = @mockDbh.sql_statements[1]
		assert_not_nil sql2 =~ /update internalClients set/, sql2
	end

	def test_group_query
		query = Query::Max.new( Client )
		assert_equal( 1, @dbb.group_query( query ).only )
		invoice = Invoice.storedTestInvoice
		query2 = Query::Max.new( Invoice, 'date' )
		assert_equal( invoice.date, @dbb.group_query( query2 ).only )
		query3 = Query::Max.new( XmlSku )
		assert_equal( 5, @dbb.group_query( query3 ).only )
	end
	
	def testLogsSql
		logFilePath = '../test/testOutput/sql'
		@dbb.execute_select( 'select * from users' )
		if FileTest.exist?( logFilePath )
			fail if Time.now - File.ctime( logFilePath ) < 5
		end
		LafcadioConfig.set_filename( '../test/testData/config_with_sql_logging.dat' )
		@dbb.execute_select( 'select * from clients' )
		fail if Time.now - File.ctime( logFilePath ) > 5
	end
	
	def testLogsSqlToDifferentFileName
		LafcadioConfig.set_filename( '../test/testData/config_with_log_path.dat' )
		logFilePath = '../test/testOutput/another.sql'
		@dbb.execute_select( 'select * from users' )
		fail if Time.now - File.ctime( logFilePath ) > 5
	end
end
