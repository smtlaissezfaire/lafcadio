require 'net/smtp'
require 'lafcadio/util/ContextualService'

class Emailer < ContextualService
	@@smtpServer = 'localhost'
	@@smtpClass = Net::SMTP
	@@messagesSent = []

	def Emailer.reset
		@@messagesSent = []
	end

	def Emailer.setSMTPClass(smtpClass)
		@@smtpClass = smtpClass
	end

	def Emailer.validAddress(address)
		(address =~ /\w@\w*\./) != nil
	end

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

	def messagesSent
		@@messagesSent
	end
end