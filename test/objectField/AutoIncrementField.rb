require 'lafcadio/test'
require '../test/mock/domain'
require 'lafcadio/objectField'

class TestAutoIncrementField < LafcadioTestCase
  def testIncrementFromNothing
    oaif = AutoIncrementField.new( Invoice, "invoice_num" )
    assert_equal("1", oaif.html_widget_value_str(nil))
  end
end