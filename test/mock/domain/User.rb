require 'lafcadio/domain/DomainObject'
require 'lafcadio/objectField/SubsetLinkField'
require 'lafcadio/objectField/EmailField'
require 'lafcadio/objectField/TextField'
require 'lafcadio/objectField/BooleanField'

class User < DomainObject
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
