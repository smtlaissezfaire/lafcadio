require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/email/Email'

class TestEmail < LafcadioTestCase
	def setup
		super
		@email = Email.new 'subject', 'recipient@test.com', 'sender@test.com',
				'test body'
	end

	def testHtmlHeaders
		@email.contentType = Email::HTML_CONTENT_TYPE
		headers = @email.headers
		assert_not_nil headers.index (
				'Content-Type: text/html; charset="iso-8859-1"'), headers.to_s
		assert_not_nil headers.index ('MIME-Version: 1.0')
	end
	
	def testMultipartHeaders
		@email.contentType = Email::MULTIPART_CONTENT_TYPE
		headers = @email.headers
		assert_not_nil headers.index (
				'Content-Type: Multipart/Alternative; charset="iso-8859-1"'), headers.to_s
	end
end