require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/xml'

class TestXmlElement < LafcadioTestCase
	def testAtts
		msgsRqElt = XmlElement.new "QBXMLMsgsRq", { 'onError' => 'continueOnError', 'this' => '& that',
				'num' => 10 }
		str = msgsRqElt.toXml
		assert_not_nil str =~ /onError="continueOnError"/
		assert_not_nil str =~ /this="&amp; that"/
	end

	def testLevel
		simple = XmlElement.new "Simple"
		assert_equal "<Simple>\n</Simple>\n", simple.toXml
		assert_equal "  <Simple>\n  </Simple>\n", simple.toXml(1)
		assert_equal "    <Simple>\n    </Simple>\n", simple.toXml(2)
	end
end