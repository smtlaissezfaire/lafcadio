require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/util/QueueHash'

class TestQueueHash < LafcadioTestCase
  def setup
    @qh = QueueHash.new("q", "w", "e", "r", "t", "y")
  end

  def testKeyValue
    assert_equal("w", @qh["q"])
    assert_equal("r", @qh["e"])
    assert_equal("y", @qh["t"])
  end

  def testOrder
    assert_equal("q", @qh.keys[0])
    assert_equal("e", @qh.keys[1])
    assert_equal("t", @qh.keys[2])
  end

  def testSize
    assert_equal(3, @qh.size)
  end

  def testValues
    values = @qh.values
    assert_equal("w", values[0])
    assert_equal("r", values[1])
    assert_equal("y", values[2])
  end

  def testAssign
    qh = QueueHash.new
    qh["a"] = 1
    qh["b"] = 2
    qh["c"] = 3
    assert_equal(1, qh["a"])
    assert_equal(1, qh.values[0])
  end

	def testNewFromArray
		qh = QueueHash.newFromArray([ 'a', 'b', 'c' ])
		assert_equal 'a', qh['a']
		assert_equal 'b', qh['b']
		assert_equal 'c', qh['c']
	end

	def testIterate
		str = ""
		@qh.each { |name, value| str += name + value }
		assert_equal 'qwerty', str
	end
end