require 'lafcadio/test/LafcadioTestCase'
require '../test/mock/domain/Invoice'
require 'lafcadio/objectField/AutoIncrementField'

class TestAutoIncrementField < LafcadioTestCase
  def testIncrementFromNothing
    oaif = AutoIncrementField.new(Invoice, "invoice_num", "Invoice No.")
    assert_equal("1", oaif.HTMLWidgetValueStr(nil))
  end
end