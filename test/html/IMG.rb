require 'runit/testcase'
require 'lafcadio/html/IMG'

class TestIMG < RUNIT::TestCase
	def testToHTML
		img = HTML::IMG.new({ 'src' => '/img/picture.gif' })
		assert_equal "<img src='/img/picture.gif'>", img.toHTML
	end

	def testRequiredAttributes
		caught = false
		begin
			img = HTML::IMG.new
		rescue
			caught = true
		end
		assert caught
	end
end