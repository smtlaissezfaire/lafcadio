require 'runit/testcase'
require 'date'
require 'lafcadio/htmlUtil/DateWidget'

class TestDateWidget < RUNIT::TestCase
	def testToHTML
		widget = DateWidget.new
		html = widget.toHTML
		widget2 = DateWidget.new('widgetName', Date.today)
		monthSelect = widget2.monthSelect
	end
	
	def testDomSelect
		widget = DateWidget.new
		html = widget.toHTML
		assert_not_nil html =~ /date.dom/
		widget.showDomSelect = false
		html2 = widget.toHTML
		assert_nil html2 =~ /date.dom/
	end
end
