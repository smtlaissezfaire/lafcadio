require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/query/Like'
require 'test/mock/domain/Invoice'

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
		assert_equal "client like '%606%'", @like1.toSql
		assert_equal "client like '%606'", @like2.toSql
		assert_equal "client like '606%'", @like3.toSql
	end
	
	def testObjectMeets
		like4 = Query::Like.new('client', '1', Invoice)
		client212 = Client.new ({ 'objId' => 212 })
		invoiceWith212 = Invoice.new ({ 'client' => client212 })
		assert like4.objectMeets(invoiceWith212)
		client234 = Client.new ({ 'objId' => 234 })
		invoiceWith234 = Invoice.new ({ 'client' => client234 })
		assert !like4.objectMeets(invoiceWith234)
	end
end