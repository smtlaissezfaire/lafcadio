require 'lafcadio/test'
require 'lafcadio/objectField'

class TestTextListField < LafcadioTestCase
	def setup
		super
		@tlf = TextListField.new nil, 'whatever'
	end

	def testValueFromSQL
		array = @tlf.value_from_sql('a,b,c')
		assert_not_nil array.index('a')
		assert_not_nil array.index('b')
		assert_not_nil array.index('c')
		assert_equal 3, array.size
		array = @tlf.value_from_sql(nil)
		assert_equal 0, array.size
	end

	def testValueForSQL
		assert_equal "'a,b,c'",(@tlf.value_for_sql([ 'a', 'b', 'c' ]))
		assert_equal "''",(@tlf.value_for_sql([ ]))
		assert_equal( "'abc'", @tlf.value_for_sql( 'abc' ) )
	end
end