require 'runit/testcase'
require 'test/mock/net/MockSmtp'
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
		MockSmtp.reset
		emailer = Emailer.new Context.instance
		Emailer.setSMTPClass MockSmtp
		email = Email.new ('subject', 'john.doe@email.com', 'me@me.com', '')
		MockSmtp.setError Net::ProtoFatalError.new('', nil), 'john.doe@email.com'
		emailer.sendEmail email
		MockSmtp.setError TimeoutError.new, 'john.doe@email.com'
		emailer.sendEmail email
		MockSmtp.setError Errno::ECONNREFUSED.new, 'john.doe@email.com'
		emailer.sendEmail email
	end
end
