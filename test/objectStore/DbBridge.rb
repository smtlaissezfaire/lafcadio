require 'test/mock/domain/InternalClient'
require "runit/testcase"
require 'test/mock/domain/Client'
require 'test/mock/domain/LineItem'
require 'lafcadio/query/Query'

class TestDBBridge < RUNIT::TestCase
  class MockResultSet
    attr_writer :rowHashes

    def initialize
      @rowHashes = []
      @cursor = 0
    end

    def each_hash
      @rowHashes.each { |hash|
        yield(hash)
      }
      return nil
    end

    def fetch_row
      row = @rowHashes[@cursor].values
      @cursor += 1
      row
    end
  end

  class MockDB
    attr_reader :lastSQL, :sqlStatements

		def initialize
			@sqlStatements = []
		end

    def query (str)
      @lastSQL = str
			@sqlStatements << str
      if str == "select last_insert_id()"
        mrs = MockResultSet.new
				mrs.rowHashes = [ { "last_insert_id()" => '12' } ]
        mrs
			elsif str == 'select max(objId) from clients'
				mrs = MockResultSet.new
				mrs.rowHashes = [ { 'max(objId)' => '1' } ]
				mrs
      else
        MockResultSet.new
      end
    end

    def getAll (objectType)
      Collection.new objectType
    end
  end

  def setup
		Config.setFilename 'lafcadio/testconfig.dat'
    @mockDB = MockDB.new
    @dbb = DbBridge.new(@mockDB)
    @client = Client.new( {"objId" => 1, "name" => "clientName1"} )
  end

  def teardown
 		DbBridge.flushConnection
		DbBridge.setDbName nil
	end

  def test_commits_delete
    @client.delete = true
    @dbb.commit(@client)
    assert_equal("delete from clients where objId=1", @mockDB.lastSQL)
  end

  def testCommitsEdit
    @dbb.commit(@client)
    sql = @mockDB.lastSQL
    assert(sql.index("update clients set name='clientName1'") != nil, sql)
  end

  class MockMysql
    @@instances = 0
    @@dbName = nil

		def MockMysql.flushInstanceCount
			@@instances = 0
		end

		def MockMysql.dbName
			@@dbName
		end

    def initialize (host, user, password)
      @@instances += 1
      raise "initialize me just once, please" if @@instances > 1
    end

    def select_db (dbName)
    	@@dbName = dbName
    end
  end

  def testConnectionPooling
    0.upto(100) { |i| DbBridge.new (nil, MockMysql) }
    DbBridge.flushConnection
  end

  def testLastObjIdInserted
    client = Client.new ( { "name" => "clientName1" } )
    @dbb.commit client
    assert_equal 12, @dbb.lastObjIdInserted
		dbb2 = DbBridge.new @mockDB
    assert_equal 12, dbb2.lastObjIdInserted
  end

	def testGetAll
		query = Query.new Domain::LineItem
		coll = @dbb.getCollectionByQuery query
		assert_equal Collection, coll.type
	end

	def testCommitsForInheritedObjects
		ic = InternalClient.new ({ 'objId' => 1, 'name' => 'client name',
				'billingType' => 'trade' })
		@dbb.commit ic
		assert_equal 2, @mockDB.sqlStatements.size
		sql1 = @mockDB.sqlStatements[0]
		assert_not_nil sql1 =~ /update internalClients set/, sql1
		sql2 = @mockDB.sqlStatements[1]
		assert_not_nil sql2 =~ /update clients set/, sql2
	end

	def testGetMax
		assert 1, @dbb.getMax(Client)
	end
	
	def testDbName
		MockMysql.flushInstanceCount
		ObjectStore.setDbName 'some_other_db'
		db = DbBridge.new nil, MockMysql
		assert_equal 'some_other_db', MockMysql.dbName
	end
end
