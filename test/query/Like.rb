require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/query/Like'
require 'test/mock/domain/Invoice'

class TestLike < LafcadioTestCase
	def setup
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
end