require 'lafcadio/email/Email'
require 'lafcadio/test/LafcadioTestCase'

class TestMockEmailer < LafcadioTestCase
	def testSendEmail
		email = Email.new "subject", "test@test.com", "your-friend@test.com",
				"hi there!"
		@mockEmailer.sendEmail email
		assert_equal 1, @mockEmailer.messagesSent.size
		assert_equal 'hi there!', @mockEmailer.messagesSent[0].body
	end
	
	class BrokenEmail
		class EmailError < StandardError
		end
	
		def verifySendable
			raise EmailError, "no", caller
		end
	end
	
	def testChecksEmailSendable
		email = BrokenEmail.new
		begin
			@mockEmailer.sendEmail email
			fail 'should raise an exception'
		rescue BrokenEmail::EmailError
			# ok
		end
	end
end