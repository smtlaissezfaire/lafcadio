require 'timeout'
require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/email/Email'
require 'test/mock/net/MockSmtp'

class TestMockSMTP < LafcadioTestCase
	def setup
		super
		MockSMTP.reset
	end

	def testMessageSent
		assert (!MockSMTP.messageSent)
		msg = [ "Subject: test subject\n", "\n", 'msg' ]
		MockSMTP.start("localhost") { |smtp|
			smtp.sendmail(msg, 'from', 'test_recipient@mail.com')
		}
		assert MockSMTP.messageSent
		assert_equal "msg", MockSMTP.lastMessage
		assert_equal String, MockSMTP.lastMessage.type
		assert_equal "test subject", MockSMTP.lastSubject
	end

	def testLastTo
		assert_nil MockSMTP.lastTo
		MockSMTP.start("localhost") { |smtp|
			smtp.sendmail('msg', 'from', 'test_recipient@email.com')
		}
		assert_equal 'test_recipient@email.com', MockSMTP.lastTo
	end

	def testNeedsTo
		caught = false
		begin
			MockSMTP.start('localhost') { |smtp|
				smtp.sendmail('msg', 'from', '')
			}
		rescue
			caught = true
		end
		assert caught
	end
	
	def testNeedsStringOrArrayOfStrings
		MockSMTP.start('localhost') { |smtp|
			smtp.sendmail('msg', 'from', "test@test.com")
		}
		MockSMTP.start('localhost') { |smtp|
			smtp.sendmail('msg', 'from', [ "test@test.com" ])
		}
		emailObject = Email.new ('subject', 'to', 'from')
		caught = false
		begin
			MockSMTP.start('localhost') { |smtp|
				smtp.sendmail('msg', 'from', emailObject)
			}
		rescue
			caught = true
		end
		assert caught
	end

	def testValid
		gmSMTP = MockSMTP.new
		assert !gmSMTP.validEmail("a")
		assert gmSMTP.validEmail("a@b.com")
	end

	def testSetError
		MockSMTP.setError TimeoutError
		begin
			MockSMTP.start('localhost') { |smtp|
				smtp.sendmail('msg', 'from', [ "test@test.com" ])
			}
			fail "TimeoutError not thrown"
		rescue TimeoutError
			# correct behavior
		end
		MockSMTP.setError TimeoutError, "test@test.com"
		begin
			MockSMTP.start('localhost') { |smtp|
				smtp.sendmail('msg', 'from', [ "test@test.com" ])
			}
			fail "TimeoutError not thrown"
		rescue TimeoutError
			# correct behavior
		end
		MockSMTP.start('localhost') { |smtp|
			smtp.sendmail('msg', 'from', [ "another@test.com" ])
		}
	end
end
