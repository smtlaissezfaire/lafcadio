require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/objectField/PasswordField'
require 'test/mock/domain/User'

class TestPasswordField < LafcadioTestCase
  def setup
  	super
    @pf = PasswordField.new User, 16
  end

  def testValueForSQL
    assert_equal("'mypassword!'", @pf.valueForSQL("mypassword!"))
  end
end
