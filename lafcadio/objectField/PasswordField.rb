require 'lafcadio/objectField/ObjectField'
require 'lafcadio/html/TR'
require 'lafcadio/objectField/PasswordFieldViewer'
require 'lafcadio/objectField/FieldValueError'
require 'lafcadio/objectField/TextField'
require 'lafcadio/objectField/PasswordField'

class PasswordField < TextField
  def PasswordField.viewerType
    PasswordFieldViewer
  end

	def PasswordField.randomPassword
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".
			  split(//)
   	value = ""
   	0.upto(8) { |i| value += chars[rand(chars.size)] }
		value
	end

  attr_reader :maxLength
	attr_accessor :autoGenerate

  def initialize (objectType, maxLength, name = "password", englishName = nil)
    super (objectType, name, englishName)
    @maxLength = maxLength
		@autoGenerate = true
  end

  def valueFromCGI (fieldManager)
    if firstTime (fieldManager) && @autoGenerate
			value = PasswordField.randomPassword
		else
      val1 = fieldManager.get("#{name}1")
      val2 = fieldManager.get("#{name}2")
      if val1 == val2
				value = val1
      else
				raise FieldValueError, "The new passwords you entered did not match.",
						caller
      end
    end
    value
  end
end

