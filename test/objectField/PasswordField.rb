require 'lafcadio/test'
require 'lafcadio/objectField'
require '../test/mock/domain/User'

class TestPasswordField < LafcadioTestCase
  def setup
  	super
    @pf = PasswordField.new User, 16
  end

  def testValueForSQL
    assert_equal("'mypassword!'", @pf.valueForSQL("mypassword!"))
  end
end
