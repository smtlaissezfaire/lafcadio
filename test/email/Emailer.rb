require 'runit/testcase'
require 'test/mock/net/MockSMTP'
require 'lafcadio/email/Email'
require 'lafcadio/email/Emailer'
require 'lafcadio/util/Context'

class TestEmailer < RUNIT::TestCase
	def testValidAddress
		assert Emailer.validAddress "francis@rhizome.org"
		assert !(Emailer.validAddress "asdf")
		assert !(Emailer.validAddress "asdf@asdf")
		assert !(Emailer.validAddress "asdf.asdf")
	end

	def testHandlesErrors
		MockSMTP.reset
		emailer = Emailer.new Context.instance
		Emailer.setSMTPClass MockSMTP
		email = Email.new ('subject', 'john.doe@email.com', 'me@me.com', '')
		MockSMTP.setError Net::ProtoFatalError.new('', nil), 'john.doe@email.com'
		emailer.sendEmail email
		MockSMTP.setError TimeoutError.new, 'john.doe@email.com'
		emailer.sendEmail email
		MockSMTP.setError Errno::ECONNREFUSED.new, 'john.doe@email.com'
		emailer.sendEmail email
	end
end
