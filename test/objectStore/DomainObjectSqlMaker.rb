require 'test/mock/domain/InternalClient'
require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/Client'
require 'test/mock/domain/Invoice'
require 'lafcadio/objectStore/DomainObjectInitError'
require 'test/mock/domain/User'
require 'lafcadio/objectStore/DomainObjectSqlMaker'

class TestDomainObjectSqlMaker < LafcadioTestCase
  def testFieldNamesForSQL
    sqlMaker = DomainObjectSqlMaker.new Invoice.getTestInvoice
    assert_equal(6, sqlMaker.getNameValuePairs(Invoice).size)
  end

  def testInsertUpdateAndDelete
    values = { "name" => "ClientName1" }
    client1a = Client.new values
    insertSql = DomainObjectSqlMaker.new(client1a).sqlStatements[0]
    values["objId"] = 1
    client1b = Client.new values
    updateSql = DomainObjectSqlMaker.new(client1b).sqlStatements[0]
    assert_not_nil updateSql.index("update")
    assert_not_nil updateSql.index("objId")
    client1b.delete = true
    deleteSql = DomainObjectSqlMaker.new(client1b).sqlStatements[0]
    assert_not_nil deleteSql.index("delete")
    assert_not_nil deleteSql.index("objId")
  end

  def testCantCommitInvalidObj
    client = Client.new ( {} )
    client.errorMessages << "Please enter a first name."
    caught = false
    begin
      DomainObjectSqlMaker.new(client).sqlStatements[0]
    rescue DomainObjectInitError
      caught = true
    end
    assert caught
  end

  def testCommitSQLWithApostrophe
    client = Client.new( { "name" => "T'est name" } )
    assert_equal("T'est name", client.name)
    sql = DomainObjectSqlMaker.new(client).sqlStatements[0]
    assert_equal("T'est name", client.name)
    assert_not_nil sql.index("'T''est name'"), sql
  end

  def testCommitSQLWithInvoice
    hash = { "client" => Client.getTestClient, "rate" => 70,
             "date" => Date.new(2001, 4, 5), "hours" => 36.5, 
						 "invoice_num" => 1, "objId" => 1 }
    invoice = Invoice.new hash
    updateSQL = DomainObjectSqlMaker.new(invoice).sqlStatements[0]
    assert_not_nil(updateSQL =~ /update invoices/, updateSQL)
    assert_not_nil(updateSQL =~ /objId=1/, updateSQL)
    invoice.delete = true
    deleteSQL = DomainObjectSqlMaker.new(invoice).sqlStatements[0]
    assert_not_nil(deleteSQL =~ /delete from invoices where objId=1/)
  end

	def testSetsNulls
		client = Client.new ({ 'objId' => 1, 'name' => 'client name',
				'referringClient' => nil, 'priorityInvoice' => nil })
		sqlMaker = DomainObjectSqlMaker.new client
		sql = sqlMaker.sqlStatements[0]
		assert_not_nil sql =~ /referringClient=null/, sql
		assert_not_nil sql =~ /priorityInvoice=null/, sql
	end

	def testInheritanceCommit
		ic = InternalClient.new ({ 'objId' => 1, 'name' => 'client name',
				'billingType' => 'trade' })
		sqlMaker = DomainObjectSqlMaker.new ic
		statements = sqlMaker.sqlStatements
		assert_equal 2, statements.size
		sql1 = statements[0]
		assert_not_nil sql1 =~ /update internalClients set/, sql1
		sql2 = statements[1]
		assert_not_nil sql2 =~ /update clients set/, sql2
	end
end
