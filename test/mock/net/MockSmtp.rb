class MockSmtp
	def MockSmtp.reset
		@@messageSent = false
		@@lastTo = nil
		@@message = nil
		@@error = nil
		@@errorEmailAddress = nil
	end

	MockSmtp.reset

	def MockSmtp.setError(error, emailAddress = nil)
		@@error = error
		@@errorEmailAddress = emailAddress
	end

  def MockSmtp.messageSent
    @@messageSent
  end

  def MockSmtp.start(hostname)
		mSMTP = MockSmtp.new
		yield mSMTP
    @@messageSent = true
		@@lastTo = mSMTP.to
		@@message = mSMTP.message
  end

	def MockSmtp.lastTo
		@@lastTo
	end

	def MockSmtp.lastMessage
		@@message.last
	end

	def MockSmtp.lastSubject
		lastSubject = nil
		i = 0
		until lastSubject || i > @@message.size
			headerLine = @@message[i]
			if headerLine =~ /^Subject: (.*)$/
				lastSubject = $1.chomp
			end
			i+= 1
		end
		lastSubject
	end

	attr_reader :to, :message

	def validEmail(email)
		(email =~ /@.*\./) != nil
	end

	def sendmail(message, from, to)
		if @@error
			if @@errorEmailAddress
				if to.class == String && @@errorEmailAddress == to
					raise @@error
				elsif to.class == Array && to.index(@@errorEmailAddress) != nil
					raise @@error
				end
			else
				raise @@error
			end
		end
		@to = to
		@message = message
		raise("invalid to email: #{to}") unless validEmail(to)
		toValidType = true
		if @to.class != String
			if @to.class == Array
				@to.each { |address|
					toValidType = false unless address.class == String
				}
			else
				toValidType = false
			end
		end
		raise("I need a string 'to' address") unless toValidType
	end
end
