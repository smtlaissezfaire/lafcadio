require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/Client'

class TestMoneyField < LafcadioTestCase
  def testvalueAsHTML
    client = Client.new( { "id" => 2, "name" => "clientName2",
			   "standard_rate" => 12 } )
    omf = MoneyField.new nil, "standard_rate"
    assert_equal("$12.00", omf.valueAsHTML(client))
  end

	def testNilToNull
    omf = MoneyField.new nil, "standard_rate"
		assert_equal String, omf.valueForSQL(nil).class
		assert_equal 'null', omf.valueForSQL(nil)
	end
end