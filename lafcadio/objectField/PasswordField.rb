require 'lafcadio/objectField/TextField'

class PasswordField < TextField
	def PasswordField.randomPassword
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".
			  split(//)
   	value = ""
   	0.upto(8) { |i| value += chars[rand(chars.size)] }
		value
	end

  attr_reader :maxLength
	attr_accessor :autoGenerate

  def initialize(objectType, maxLength, name = "password", englishName = nil)
    super(objectType, name, englishName)
    @maxLength = maxLength
		@autoGenerate = true
  end
end

