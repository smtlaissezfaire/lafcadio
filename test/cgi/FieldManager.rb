require 'test/mock/domain/Invoice'
require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/User'
require 'lafcadio/cgi/FieldManager'

class TestFieldManager < LafcadioTestCase
  class MockCGI < Hash
    def initialize (aHash)
      aHash.keys.each { |key| self[key] = aHash[key] }
    end

    def [] (key)
      value = super key
      self[key] = nil
      value
    end
  end

	def fieldManager (aHash)
		FieldManager.new MockCGI.new aHash
	end

  def test_returns_nil
		fm = fieldManager ({ 'name' => [] })
    assert_nil(fm.get("name"))
		fm = fieldManager ({ 'name' => [ '' ] })
		assert_equal '', fm.get('name')
		fm = fieldManager ({})
    assert_nil(fm.get("objId"))
  end

  def testGetDate
		fm = fieldManager ({ "date.month" => ["4"], "date.dom" => ["1"],
												 "date.year" => ["1998"] })
    date = fm.getDate
    assert_equal (4, date.mon)
    assert_equal (1, date.mday)
    assert_equal (1998, date.year)
		assert_nil fm.getDate ('absentDate')
  end

  def testNoDateIfAnyFieldsAreIncomplete
		fm = fieldManager ({ "date.month" => ["4"], "date.dom" => ["0"],
												 "date.year" => ["0"] })
    assert_nil fm.getDate
  end

  class UndumpableCGI < Hash
    def _dump (aDepth)
      raise "don't dump me"
    end
  end

  def testDumpable
    Marshal.dump(FieldManager.new(UndumpableCGI.new))
  end

  def testGetObjectType
		fm = fieldManager ({ "objectType" => ["User"],
												 "anotherObjectType" => ["Client"] })
    assert_equal(User, fm.getObjectType)
		assert_equal Client, fm.getObjectType("anotherObjectType")
		fm.set('objectType', 'Invoice')
		assert_equal Invoice, fm.getObjectType
		fm.set('objectType', nil)
		assert_equal nil, fm.getObjectType
		fm.set('objectType', '')
		assert_equal nil, fm.getObjectType
  end

	def testOnlyAcceptStringKeys
		fm = FieldManager.new(MockCGI.new( {} ))
		caught = false
		begin
			fm.get(1)
		rescue
			caught = true
		end
		assert caught
	end

	def testWithArrays
		fm = fieldManager ({ "Attribute" => [ "1", "2" ], "Product" => [ "10" ] })
		assert_equal 2, fm.getArray("Attribute").size
		assert_equal 1, fm.getArray("Product").size
		assert_equal 10, fm.getInt("Product")
	end

	def testSet
		fm = fieldManager ({ "Product" => [ "new" ] })
		assert_equal "new", fm.get("Product")
		fm.set("Product", 1)
		assert_equal 1, fm.get("Product")
	end

	def testSetDate
		fm = fieldManager ({ 'date.year' => [ '2001' ], 'date.month' => [ '5' ],
												 'date.dom' => [ '4' ] })
		assert_equal 2001, fm.getDate('date').year
		fm.setDate ('date', Date.new(2002, 9, 10))
		date = fm.getDate('date')
		assert_equal 2002, date.year
		assert_equal 9, date.month
		assert_equal 10, date.day
	end
end

