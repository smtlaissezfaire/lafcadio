require 'lafcadio/test'
require 'lafcadio/query'
require '../test/mock/domain/InternalClient'
require '../test/mock/domain/Invoice'

class TestLike < LafcadioTestCase
	def setup
		super
		@like1 = Query::Like.new('client', '606', Invoice)
		@like2 = Query::Like.new('client', '606', Invoice,
				Query::Like::PRE_ONLY)
		@like3 = Query::Like.new('client', '606', Invoice,
				Query::Like::POST_ONLY)
	end

	def testToSql
		assert_equal( "invoices.client like '%606%'", @like1.toSql )
		assert_equal( "invoices.client like '%606'", @like2.toSql )
		assert_equal( "invoices.client like '606%'", @like3.toSql )
	end
	
	def testObjectMeets
		like4 = Query::Like.new('client', '1', Invoice)
		client212 = Client.new({ 'pkId' => 212 })
		invoiceWith212 = Invoice.new({ 'client' => client212 })
		assert like4.objectMeets(invoiceWith212)
		client234 = Client.new({ 'pkId' => 234 })
		invoiceWith234 = Invoice.new({ 'client' => client234 })
		assert !like4.objectMeets(invoiceWith234)
	end
	
	def testFieldBelongingToSuperclass
		condition = Query::Like.new('name', 'client name', InternalClient)
		assert_equal( "clients.name like '%client name%'", condition.toSql )
	end

	def testDbFieldName
		condition = Query::Like.new( 'text1', 'foobar', XmlSku )
		assert_equal( "some_other_table.text_one like '%foobar%'", condition.toSql )
	end
end