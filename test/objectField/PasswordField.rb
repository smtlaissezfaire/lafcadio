require 'lafcadio/test'
require 'lafcadio/objectField'
require '../test/mock/domain'

class TestPasswordField < LafcadioTestCase
  def setup
  	super
    @pf = PasswordField.new User, 16
  end

  def testValueForSQL
    assert_equal("'mypassword!'", @pf.value_for_sql("mypassword!"))
  end
end
