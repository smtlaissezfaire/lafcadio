require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/xml/XmlTextElement'

class TestXmlTextElement < LafcadioTestCase
	def testTo_s
		simple = XmlTextElement.new "name", "contents"
		assert_equal "<name>contents</name>\n", simple.toXml
		assert_equal "  <name>contents</name>\n", simple.toXml(1)
		escapeMe = XmlTextElement.new "escape", "< > & ' \""
		assert_equal "<escape>&lt; &gt; &amp; &apos; &quot;</escape>\n", escapeMe.toXml
		nilElt = XmlTextElement.new "nothing", nil
		assert_equal "<nothing></nothing>\n", nilElt.toXml
	end

	def testWithNum
		num = XmlTextElement.new "number", 9
		assert_equal "<number>9</number>\n", num.toXml
	end
end