require 'lafcadio/domain'
require 'lafcadio/objectField/SubsetLinkField'
require 'lafcadio/objectField'

class User < Lafcadio::DomainObject
  def User.fieldHash
    fieldHash = { "salutation" => "Mr", "firstNames" => "Francis",
		  "lastName" => "Hwang", "phone" => "", "address1" => "",
		  "address2" => "", "city" => "", "state" => "", "zip" => "",
		  "email" => "test@test.com", "password" => "mypassword!" }
  end

  def User.getTestUser
		User.new fieldHash
  end

  def User.getTestUserWithPkId
    myHash = fieldHash
    myHash["pkId"] = 1
    user = User.new myHash
		Context.instance.getObjectStore.addObject user
		user
  end
end
