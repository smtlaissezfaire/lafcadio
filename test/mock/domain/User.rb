require 'lafcadio/domain/DomainObject'
require 'lafcadio/objectField/SubsetLinkField'
require 'lafcadio/objectField/EmailField'
require 'lafcadio/objectField/TextField'

class User < DomainObject
  def User.classFields
    fields = []
    emailField = EmailField.new User
    emailField.unique = true
    emailField.writeOnce = true
		emailField.notUniqueMsg = <<-MSG
A profile already exists for the email address that you have entered.
Please choose another email address.
		MSG
		fields << emailField
		fields <<(TextField.new(self, 'firstNames'))
    fields
  end

  def User.fieldHash
    fieldHash = { "salutation" => "Mr", "firstNames" => "Francis",
		  "lastName" => "Hwang", "phone" => "", "address1" => "",
		  "address2" => "", "city" => "", "state" => "", "zip" => "",
		  "email" => "test@test.com", "password" => "mypassword!" }
  end

  def User.getTestUser
		User.new fieldHash
  end

  def User.getTestUserWithObjId
    myHash = fieldHash
    myHash["objId"] = 1
    user = User.new myHash
		Context.instance.getObjectStore.addObject user
		user
  end
end
