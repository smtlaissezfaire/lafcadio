class MockEmailer
	attr_reader :messagesSent

	def initialize
		@messagesSent = []
	end
	
	def sendEmail(email)
		email.verifySendable
		@messagesSent << email
	end
end