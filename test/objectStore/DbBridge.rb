require '../test/mock/domain/InternalClient'
require "runit/testcase"
require '../test/mock/domain/Client'
require '../test/mock/domain/LineItem'
require 'lafcadio/query/Query'

class TestDBBridge < RUNIT::TestCase
	include Lafcadio

  class MockDbh
  	@@connected = false
  
    attr_reader :lastSQL, :sqlStatements
    
		def initialize
			@sqlStatements = []
			@@connected = true
		end
		
		def do( sql, *binds )
			logSql( sql )
		end
		
		def logSql( sql )
      @lastSQL = sql
			@sqlStatements << sql
		end

    def select_all(str)
			logSql( str )
      if str == "select last_insert_id()"
				[ { 'last_insert_id()' => '12' } ]
			elsif str == 'select max(pkId) from clients'
				[ [ '1' ] ]
			elsif str == 'select max(date) from invoices'
				[ [ DBI::Date.new( 2001, 4, 5 ) ] ]
			elsif str == 'select * from some_other_table'
				[ OneTimeAccessHash.new( 'some_other_id' => '16', 'text1' => 'foobar',
				                         'link1' => '1' ) ]
      else
				[]
      end
    end

    def getAll(objectType); []; end
    
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
		LafcadioConfig.setFilename 'lafcadio/test/testconfig.dat'
    @mockDbh = MockDbh.new
    @dbb = DbBridge.new(@mockDbh)
    @client = Client.new( {"pkId" => 1, "name" => "clientName1"} )
  end

  def teardown
		@dbb = nil
 		DbBridge.flushConnection
		DbBridge.setDbName nil
	end

  def test_commits_delete
    @client.delete = true
    @dbb.commit(@client)
    assert_equal("delete from clients where pkId=1", @mockDbh.lastSQL)
  end

  def testCommitsEdit
    @dbb.commit(@client)
    sql = @mockDbh.lastSQL
    assert(sql.index("update clients set name='clientName1'") != nil, sql)
  end
	
	def test_passes_sql_value_converter_to_domain_class_init
		query = Query.new( XmlSku )
		xml_sku = @dbb.getCollectionByQuery( query ).only
		assert_equal( 'foobar', xml_sku.text1 )
		assert_equal( 'foobar', xml_sku.text1 )
		assert_nil( xml_sku.date1 )
		assert_nil( xml_sku.date1 )
		assert_equal( DomainObjectProxy, xml_sku.link1.class )
		assert_equal( 1, xml_sku.link1.pkId )
	end

  class MockDbi
    @@instances = 0
    @@dbName = nil

		def MockDbi.connect( dbAndHost, user, password )
			@@dbName = dbAndHost.split(':')[2]
      @@instances += 1
      raise "initialize me just once, please" if @@instances > 1
      return MockDbh.new
		end

		def MockDbi.flushInstanceCount
			@@instances = 0
		end

		def MockDbi.dbName
			@@dbName
		end
  end

  def testConnectionPooling
  	DbBridge.setConnectionClass( MockDbi )
    100.times { DbBridge.new }
    DbBridge.flushConnection
    DbBridge.setConnectionClass( DBI )
  end

  def testLastPkIdInserted
    client = Client.new( { "name" => "clientName1" } )
    @dbb.commit client
    assert_equal 12, @dbb.lastPkIdInserted
		dbb2 = DbBridge.new @mockDbh
    assert_equal 12, dbb2.lastPkIdInserted
  end

	def testGetAll
		query = Query.new Domain::LineItem
		coll = @dbb.getCollectionByQuery query
		assert_equal Array, coll.class
	end

	def testCommitsForInheritedObjects
		ic = InternalClient.new({ 'pkId' => 1, 'name' => 'client name',
				'billingType' => 'trade' })
		@dbb.commit ic
		assert_equal 2, @mockDbh.sqlStatements.size
		sql1 = @mockDbh.sqlStatements[0]
		assert_not_nil sql1 =~ /update clients set/, sql1
		sql2 = @mockDbh.sqlStatements[1]
		assert_not_nil sql2 =~ /update internalClients set/, sql2
	end

	def test_group_query
		query = Query::Max.new( Client )
		assert_equal( 1, @dbb.group_query( query ).only )
		invoice = Invoice.storedTestInvoice
		query2 = Query::Max.new( Invoice, 'date' )
		assert_equal( invoice.date, @dbb.group_query( query2 ).only )
	end
	
	def testDbName
  	DbBridge.setConnectionClass( MockDbi )
  	DbBridge.flushConnection
		MockDbi.flushInstanceCount
		ObjectStore.setDbName 'some_other_db'
		db = DbBridge.new( nil )
		assert_equal 'some_other_db', MockDbi.dbName
    DbBridge.setConnectionClass( DBI )
	end
	
	def testLogsSql
		logFilePath = '../test/testOutput/sql'
		@dbb.executeSelect( 'select * from users' )
		if FileTest.exist?( logFilePath )
			fail if Time.now - File.ctime( logFilePath ) < 5
		end
		LafcadioConfig.setFilename( '../test/testData/config_with_sql_logging.dat' )
		@dbb.executeSelect( 'select * from clients' )
		fail if Time.now - File.ctime( logFilePath ) > 5
	end
	
	def testLogsSqlToDifferentFileName
		LafcadioConfig.setFilename( '../test/testData/config_with_log_path.dat' )
		logFilePath = '../test/testOutput/another.sql'
		@dbb.executeSelect( 'select * from users' )
		fail if Time.now - File.ctime( logFilePath ) > 5
	end
	
	def testDisconnect
		DbBridge.disconnect
		assert !@mockDbh.connected?
	end
end
