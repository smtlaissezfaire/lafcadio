require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/dateTime/Month'
require 'lafcadio/util/HashOfArrays'

class TestHashOfArrays < LafcadioTestCase
	def testCantAssignNonArrayValue
		caught = false
		hoa = HashOfArrays.new
		begin
			hoa.set(1, 2)
		rescue
			caught = true
		end
		assert caught
	end

	def testAppendToNewArray
		hoa = HashOfArrays.new
		hoa.getArray(1) << 2
		assert_equal 1, hoa.getArray(1).size
	end

	def testValues
		hoa = HashOfArrays.new
		hoa.getArray(1) << "a"
		hoa.getArray(2) << "b"
		aFound = false
		bFound = false
		hoa.values.each { |value|
			aFound = true if value == "a"
			bFound = true if value == "b"
		}
		assert aFound
		assert bFound
	end

	def testKeys
		hoa = HashOfArrays.new
		hoa.getArray(1) << "a"
		hoa.getArray(2) << 'b'
		oneFound = false
		twoFound = false
		hoa.keys.each { |key|
			oneFound = true if key == 1
			twoFound = true if key == 2
		}
		assert oneFound
		assert twoFound
	end

	def testComplexKeys
		jan2000 = Month.new 1, 2000
		dec2000 = Month.new 12, 2000
		jan2001 = Month.new 1, 2001
		jan2001Prime = Month.new 1, 2001
		hoa = HashOfArrays.new
		hoa.getArray(jan2000) << "a"
		hoa.getArray(dec2000) << "a"
		hoa.getArray(jan2001) << "a"
		assert_equal 3, hoa.keys.size
		hoa.getArray(jan2001Prime) << "b"
		assert_equal 3, hoa.keys.size
	end

	def testEach
		hoa = HashOfArrays.new
		hoa[1] = [ 'a', 'b' ]
		hoa[2] = [ 'c', 'd', 'e' ]
		hoa.each { |key, array|
			if key == 1
				assert_equal [ 'a', 'b' ], array
			elsif key == 2
				assert_equal [ 'c', 'd', 'e' ], array
			else
				fail "key #{ key }"
			end
		}
	end
end