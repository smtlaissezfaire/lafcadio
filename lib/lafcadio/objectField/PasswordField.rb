require 'lafcadio/objectField/TextField'

module Lafcadio
	# A PasswordField is simply a TextField that is expected to contain a password
	# value. It can be set to auto-generate a password at random.
	class PasswordField < TextField
		# Returns a random 8-letter alphanumeric password.
		def PasswordField.randomPassword
			chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".
					split(//)
			value = ""
			0.upto(8) { |i| value += chars[rand(chars.size)] }
			value
		end
	end
end
