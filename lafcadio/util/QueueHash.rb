class QueueHash
	def QueueHash.newFromArray(array)
		valueArray = []
		array.each { |elt|
			valueArray << elt
			valueArray << elt
		}
		new(*valueArray)
	end

  def initialize(*values)
    @pairs = []
    0.step(values.size-1, 2) { |i| @pairs << [ values[i], values[i+1] ] }
  end

  def keys
    keys = []
    @pairs.each { |pair| keys << pair[0] }
    keys
  end

  def values
    values = []
    @pairs.each { |pair| values << pair[1] }
    values
  end

  def [](key)
    value = nil
    @pairs.each { |pair| value = pair[1] if pair[0] == key }
    value
  end

  def size
    @pairs.size
  end

  def []=(key, value)
    @pairs << [key, value]
  end

	def each
		@pairs.each { |pair| yield pair[0], pair[1] }
	end
end