require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/objectField/MoneyField'

class TestMoneyFieldViewer < LafcadioTestCase
  def testMoneyDollarSign
    omf = MoneyField.new nil, "rate"
		html = omf.viewer('', nil).toHTMLWidget
    assert(html.index("$") != nil)
  end

  def testMoneyFieldSize
    omf = MoneyField.new nil, "rate"
		html = omf.viewer(nil, nil).toHTMLWidget
		assert_not_nil html.index("size='6'")
  end

  def testMoneyIncludesValue
    omf = MoneyField.new nil, "rate"
		html = omf.viewer(1.55, nil).toHTMLWidget
    assert_not_nil(html.index("value='1.55'"), html)
		html = omf.viewer(1, nil).toHTMLWidget
    assert_not_nil(html.index("value='1.00'"), html)
  end
end
