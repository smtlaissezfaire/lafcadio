require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/objectField/PasswordField'
require 'test/mock/domain/User'

class TestPasswordFieldViewer < LafcadioTestCase
  def testPasswordReturnsFormRowNotDisplayRow
    pf = PasswordField.new User, 16
		viewer = pf.viewer('', nil)
    assert_nil viewer.toDisplayRow
    assert_not_nil viewer.toAeFormRows
  end

  def testPasswordToAeFormRows
    pf = PasswordField.new User, 16
		rows = pf.viewer('', nil).toAeFormRows
    assert_not_nil rows[0].toHTML.index("type='password'")
    assert_not_nil rows[1].toHTML.index("re-enter"), rows[1].toHTML
  end

  def testPasswordDontPresetWidgetValue
    pf = PasswordField.new User, 16
		rows = pf.viewer('zastruga', nil).toAeFormRows
    assert_nil rows[0].toHTML.index("zastruga")
    assert_nil rows[1].toHTML.index("zastruga")
  end
end