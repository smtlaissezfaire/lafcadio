require 'lafcadio/objectStore'
require 'test/unit'

class TestDbConnection < Test::Unit::TestCase
	include Lafcadio

  def setup
		LafcadioConfig.set_filename 'lafcadio/test/testconfig.dat'
    @mockDbh = MockDbh.new
    DbConnection.set_dbh( @mockDbh )
  end

  def testConnectionPooling
  	DbConnection.set_connection_class( MockDbi )
    100.times { DbConnection.get_db_connection }
    DbConnection.flush
    DbConnection.set_connection_class( DBI )
  end

	def testDbName
  	DbConnection.set_connection_class( MockDbi )
  	DbConnection.flush
		MockDbi.flushInstanceCount
		ObjectStore.set_db_name 'some_other_db'
		db = DbBridge.new
		assert_equal 'some_other_db', MockDbi.dbName
    DbConnection.set_connection_class( DBI )
	end
	
	def testDisconnect
		DbConnection.get_db_connection.disconnect
		assert !@mockDbh.connected?
	end

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
				[ OneTimeAccessHash.new( 'some_other_id' => '16', 'text1' => 'foobar',
				                         'link1' => '1' ) ]
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
end