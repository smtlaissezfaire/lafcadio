require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/xml/XmlSelfEndingElement'

class TestXmlSelfEndingElement < LafcadioTestCase
	def testToS
		elt = XmlSelfEndingElement.new 'test', { 'att' => 'value' }
		assert_equal "<test att=\"value\"/>\n", elt.toXml
		assert_equal "  <test att=\"value\"/>\n", elt.toXml(1)
	end
end