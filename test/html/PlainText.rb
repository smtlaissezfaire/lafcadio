require 'runit/testcase'
require 'lafcadio/html/PlainText'

class TestPlainText < RUNIT::TestCase
	def convert (text)
		pt = PlainText.new text
		pt.toHtml
	end

	def testChangeNewlines
		assert_equal "here's a \n<br>break tag", (convert ("here's a \nbreak tag"))
		assert_equal "here's a \n<p>paragraph", (convert ("here's a \n\nparagraph"))
	end

	def testChangesBrackets
		assert_equal "&gt;", convert(">")
		assert_equal "&lt;", convert("<")
	end

	def testFaintColorsForQuotedLines
		assert_equal "<span class=\"quoted_text\">&gt; " +
				"that's what you said</span>",
				(convert ("> that's what you said"))
		assert_equal "<span class=\"quoted_text\">&gt; that's what \n" +
				"<br>&gt; you said</span>",
				(convert ("> that's what \n> you said"))
		assert_equal "<span class=\"quoted_text\">&gt; " +
				"that's what you said</span>\n<p>Here's what I say",
				(convert ("> that's what you said\n\nHere's what I say"))
	end

	def testCreateHtmlLinks
		assert_equal "<a href=\"http://google.com\">http://google.com</a>",
				(convert ("http://google.com"))
	end
end