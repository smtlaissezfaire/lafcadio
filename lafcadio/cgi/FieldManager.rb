require 'cgi'
require 'date'

# Lafcadio uses FieldManager to wrap and abstract CGI arguments.
class FieldManager
  def initialize(cgi = nil)
		require 'lafcadio/util/HashOfArrays'
    cgi = CGI.new if cgi == nil
		@valueHash = HashOfArrays.new
    cgi.keys.each { |key|
			valueArray = cgi.params[key]
			@valueHash.set(key, valueArray)
    }
  end

	# Return the value for this key. If the FieldManager contains an array of
	# values corresponding to this key, the first value will be returned.
  def get(fieldName)
		raise "FieldManager only takes String keys" unless fieldName.class == String
		@valueHash.get fieldName
  end

	# Return the corresponding array for this key. If the FieldManager only
	# contains a single value for this key, a one-element array will be returned.
	def getArray(fieldName)
		@valueHash.getArray fieldName
	end

	# Returns the value for this key as a decimal integer.
  def getInt(fieldName)
    value = get fieldName
    value != nil ? value.to_i : nil
  end

	# Returns the value for this key as a float.
	def getFloat(fieldName)
		value = get fieldName
		value ? value.to_f : nil
	end

	# Returns the value for this key as a date. This method assumes that it has
	# received three separate CGI fields for this key, ending in ".year",
	# ".month", and ".dom".
  def getDate(fieldName = "date")
    year = getInt("#{fieldName}.year")
    month = getInt("#{fieldName}.month")
    dom = getInt("#{fieldName}.dom")
		if year && year != 0 && month && month != 0 && dom && dom != 0
      Date.new(year, month, dom)
    else
      nil
    end
  end

	# Returns the value for the key "objId".
  def getObjId
    getInt("objId")
  end

	# Returns the domain class for the corresponding key.
  def getObjectType(key = "objectType")
  	require 'lafcadio/util/DomainUtil'
		objTypeString = get key
		if(objTypeString && objTypeString != '')
			DomainUtil.getObjectTypeFromString get(key)
		end
  end

	# Sets the value for one key.
	def set(key, value)
		@valueHash.set(key, [value])
	end

	# Sets a date for one key.
	def setDate(dateName, date)
		@valueHash.set( dateName + ".year", [date.year] )
		@valueHash.set(dateName + ".month", [date.month] )
		@valueHash.set(dateName + ".dom", [date.day] )
	end

	def keys
		@valueHash.keys
	end

	# Returns a hash with the same key-value associations. Note that array values
	# are lost: Only the first value in an array is preserved.
	def to_hash
		hash = {}
		@valueHash.keys.each { |key| hash[key] = get key }
		hash
	end

	# Returns a string representation.
	def dump
		str = ""
		@valueHash.keys.each { |key|
			line = "#{key}: "
			line += @valueHash.getArray(key).join(", ")
			line += "\n"
			str += line
		}
		str
	end
end

