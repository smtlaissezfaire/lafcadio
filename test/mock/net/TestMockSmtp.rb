require 'timeout'
require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/email/Email'
require 'test/mock/net/MockSmtp'

class TestMockSmtp < LafcadioTestCase
	def setup
		super
		MockSmtp.reset
	end

	def testMessageSent
		assert(!MockSmtp.messageSent)
		msg = [ "Subject: test subject\n", "\n", 'msg' ]
		MockSmtp.start("localhost") { |smtp|
			smtp.sendmail(msg, 'from', 'test_recipient@mail.com')
		}
		assert MockSmtp.messageSent
		assert_equal "msg", MockSmtp.lastMessage
		assert_equal String, MockSmtp.lastMessage.class
		assert_equal "test subject", MockSmtp.lastSubject
	end

	def testLastTo
		assert_nil MockSmtp.lastTo
		MockSmtp.start("localhost") { |smtp|
			smtp.sendmail('msg', 'from', 'test_recipient@email.com')
		}
		assert_equal 'test_recipient@email.com', MockSmtp.lastTo
	end

	def testNeedsTo
		caught = false
		begin
			MockSmtp.start('localhost') { |smtp|
				smtp.sendmail('msg', 'from', '')
			}
		rescue
			caught = true
		end
		assert caught
	end
	
	def testNeedsStringOrArrayOfStrings
		MockSmtp.start('localhost') { |smtp|
			smtp.sendmail('msg', 'from', "test@test.com")
		}
		MockSmtp.start('localhost') { |smtp|
			smtp.sendmail('msg', 'from', [ "test@test.com" ])
		}
		emailObject = Email.new('subject', 'to', 'from')
		caught = false
		begin
			MockSmtp.start('localhost') { |smtp|
				smtp.sendmail('msg', 'from', emailObject)
			}
		rescue
			caught = true
		end
		assert caught
	end

	def testValid
		gmSMTP = MockSmtp.new
		assert !gmSMTP.validEmail("a")
		assert gmSMTP.validEmail("a@b.com")
	end

	def testSetError
		MockSmtp.setError TimeoutError
		begin
			MockSmtp.start('localhost') { |smtp|
				smtp.sendmail('msg', 'from', [ "test@test.com" ])
			}
			fail "TimeoutError not thrown"
		rescue TimeoutError
			# correct behavior
		end
		MockSmtp.setError TimeoutError, "test@test.com"
		begin
			MockSmtp.start('localhost') { |smtp|
				smtp.sendmail('msg', 'from', [ "test@test.com" ])
			}
			fail "TimeoutError not thrown"
		rescue TimeoutError
			# correct behavior
		end
		MockSmtp.start('localhost') { |smtp|
			smtp.sendmail('msg', 'from', [ "another@test.com" ])
		}
	end
end
