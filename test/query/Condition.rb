require 'lafcadio/query'
require 'lafcadio/test'
require 'test/mock/domain'

class TestCondition < LafcadioTestCase
	def testRaisesExceptionIfInitHasWrongArguments
		cond = Query::Condition.new( 'att name', 'name', Attribute )
		begin
			cond.getField
			fail "needs to raise MissingError"
		rescue MissingError
			errStr = "Couldn't find field \"att name\" in Attribute domain class"
			assert_equals( $!.to_s, errStr )
		end
	end
end