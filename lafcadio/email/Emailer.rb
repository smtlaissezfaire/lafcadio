require 'net/smtp'
require 'lafcadio/util/ContextualService'

class Emailer < ContextualService
	@@smtpServer = 'localhost'
	@@smtpClass = Net::SMTP
	@@messagesSent = []

	# Resets record of messages sent.
	def Emailer.reset
		@@messagesSent = []
	end

	def Emailer.setSMTPClass(smtpClass)
		@@smtpClass = smtpClass
	end

	# Returns a boolean value describing whether <tt>address</tt> is a plausible 
	# email address format.
	def Emailer.validAddress(address)
		(address =~ /\w@\w*\./) != nil
	end

	# Sends an email message.
	def sendEmail(email)
		email.verifySendable
		msg = []
		email.headers.each { |header| msg << "#{header}\n" }
		msg << "\n"
		msg << email.body
		begin
			@@smtpClass.start( @@smtpServer ) { |smtp|
				smtp.sendmail(msg, email.fromAddress, [ email.toAddress ])
			}
			@@messagesSent << email
		rescue Net::ProtoFatalError, TimeoutError, Errno::ECONNREFUSED,
				Errno::ECONNRESET
			# whatever
		end
	end

	# Returns an array of what messages have been sent.
	def messagesSent
		@@messagesSent
	end
end