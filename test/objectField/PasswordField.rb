require 'lafcadio/mock/MockFieldManager'
require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/cgi/FieldManager'
require 'lafcadio/objectField/PasswordField'
require 'test/mock/domain/User'

class TestPasswordField < LafcadioTestCase
  def setup
  	super
    @pf = PasswordField.new User, 16
  end

  def testValueFromCGINewUser
    fm = FieldManager.new({})
    previous = []
    0.upto(20) { |i|
      nextRnd = @pf.valueFromCGI fm
      previous.each { |prev| fail if prev == nextRnd }
      previous << nextRnd
    }
  end

  def testValueFromCGIPrevUser
    fm = MockFieldManager.new( { "objId" => "1" } )
    assert_nil @pf.valueFromCGI(fm)
    fmEdit = MockFieldManager.new({ "objId" => "1", "password1" => "newpass",
				     "password2" => "newpass" })
    assert_equal("newpass", @pf.valueFromCGI(fmEdit))
    badEditHash = { "objId" => "1", "password1" => "newpass",
		    "password2" => "newpasd" }
    fmEditWrong = MockFieldManager.new badEditHash
    caught = false
    begin
      @pf.valueFromCGI(fmEditWrong)
    rescue
      caught = true
    end
    assert caught
  end

  def testValueForSQL
    assert_equal("'mypassword!'", @pf.valueForSQL("mypassword!"))
  end

	def testDontAutoGenerate
		@pf.autoGenerate = false
		fm = FieldManager.new({})
		assert_nil @pf.valueFromCGI(fm)
		caught = false
		begin
			@pf.verifiedValue(fm)
		rescue FieldValueError
			caught = true
		end
		assert caught
		fm2 = MockFieldManager.new({ 'password1' => 'abc',
																	 'password2' => 'def' })
		caught = false
		begin
			@pf.verifiedValue(fm2)
		rescue FieldValueError
			caught = true
		end
		assert caught
		fm3 = MockFieldManager.new({ 'password1' => 'abc',
																	 'password2' => 'abc' })
		assert_equal 'abc', @pf.verifiedValue(fm3)
	end
end
