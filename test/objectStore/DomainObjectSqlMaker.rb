require 'lafcadio/test'
require '../test/mock/domain'
require '../test/mock/domain/Invoice'
require 'lafcadio/objectStore'
require '../test/mock/domain/User'

class TestDomainObjectSqlMaker < LafcadioTestCase
  def testFieldNamesForSQL
    sqlMaker = DomainObjectSqlMaker.new Invoice.getTestInvoice
    assert_equal(7, sqlMaker.get_name_value_pairs(Invoice).size)
  end

  def testInsertUpdateAndDelete
    values = { "name" => "ClientName1" }
    client1a = Client.new values
    insertSql = DomainObjectSqlMaker.new(client1a).sql_statements[0]
    values["pk_id"] = 1
    client1b = Client.new values
    updateSql = DomainObjectSqlMaker.new(client1b).sql_statements[0][0]
		assert_match( /update/, updateSql )
    assert_not_nil updateSql.index("pk_id")
    client1b.delete = true
    delete_sql = DomainObjectSqlMaker.new(client1b).sql_statements[0][0]
    assert_not_nil delete_sql.index("delete")
    assert_not_nil delete_sql.index("pk_id")
		binds = DomainObjectSqlMaker.new(client1b).sql_statements[0][1]
		assert_not_nil( binds )
		assert_equal( 0, binds.size )
  end

  def testCantCommitInvalidObj
    client = Client.new( {} )
    client.error_messages << "Please enter a first name."
    caught = false
    begin
      DomainObjectSqlMaker.new(client).sql_statements[0]
    rescue DomainObjectInitError
      caught = true
    end
    assert caught
  end

  def testCommitSQLWithApostrophe
    client = Client.new( { "name" => "T'est name" } )
    assert_equal("T'est name", client.name)
    sql = DomainObjectSqlMaker.new(client).sql_statements[0][0]
    assert_equal("T'est name", client.name)
    assert_not_nil sql.index("'T''est name'"), sql
  end

  def testCommitSQLWithInvoice
    hash = { "client" => Client.getTestClient, "rate" => 70,
             "date" => Date.new(2001, 4, 5), "hours" => 36.5, 
						 "invoice_num" => 1, "pk_id" => 1 }
    invoice = Invoice.new hash
    update_sql = DomainObjectSqlMaker.new(invoice).sql_statements[0]
    assert_not_nil(update_sql =~ /update invoices/, update_sql)
    assert_not_nil(update_sql =~ /pk_id=1/, update_sql)
    invoice.delete = true
    deleteSQL = DomainObjectSqlMaker.new(invoice).sql_statements[0]
    assert_not_nil(deleteSQL =~ /delete from invoices where pk_id=1/)
  end

	def testSetsNulls
		client = Client.new({ 'pk_id' => 1, 'name' => 'client name',
				'referringClient' => nil, 'priorityInvoice' => nil })
		sqlMaker = DomainObjectSqlMaker.new client
		sql = sqlMaker.sql_statements[0]
		assert_not_nil sql =~ /referringClient=null/, sql
		assert_not_nil sql =~ /priorityInvoice=null/, sql
	end

	def testInheritanceCommit
		ic = InternalClient.new({ 'pk_id' => 1, 'name' => 'client name',
				'billingType' => 'trade' })
		sqlMaker = DomainObjectSqlMaker.new ic
		statements = sqlMaker.sql_statements
		assert_equal 2, statements.size
		sql1 = statements[0]
		assert_not_nil sql1 =~ /update internalClients set/, sql1
		sql2 = statements[1]
		assert_not_nil sql2 =~ /update clients set/, sql2
	end
	
	class InternalClientDiffPk < Client
		def self.get_class_fields; [ TextField.new( self, 'billingType' ) ]; end
		
		def self.sql_primary_key_name; 'primary_key'; end
		
		def self.table_name; 'internalClients'; end
	end

	def test_inheritance_insert
		ic = InternalClientDiffPk.new( 'name' => 'client name',
		                               'billingType' => 'trade' )
		sql_maker = DomainObjectSqlMaker.new( ic )
		statements = sql_maker.sql_statements
		assert_equal( 2, statements.size )
		sql1 = statements[0].first
		assert_match( /insert into clients/, sql1 )
		bind1 = statements[0].last
		assert_equal( 1, bind1.size )
		sql2 = statements[1].first
		assert_match( /insert into internalClients.*primary_key/, sql2 )
		assert_match( /values.*LAST_INSERT_ID\(\)/, sql2 )
		bind2 = statements[1].last
		assert_equal( 0, bind2.size )
	end
end
