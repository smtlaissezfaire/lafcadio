require 'cgi'
require 'date'

class FieldManager
  def initialize (cgi = nil)
		require 'lafcadio/util/HashOfArrays'
    cgi = CGI.new if cgi == nil
		@valueHash = HashOfArrays.new
    cgi.keys.each { |key|
			valueArray = cgi[key]
			@valueHash.set(key, valueArray)
    }
  end

  def get (fieldName)
		raise "FieldManager only takes String keys" unless fieldName.type == String
		@valueHash.get fieldName
  end

	def getArray (fieldName)
		@valueHash.getArray fieldName
	end

  def getInt (fieldName)
    value = get fieldName
    value != nil ? value.to_i : nil
  end

	def getFloat (fieldName)
		value = get fieldName
		value ? value.to_f : nil
	end

  def getDate (fieldName = "date")
    year = getInt("#{fieldName}.year")
    month = getInt("#{fieldName}.month")
    dom = getInt("#{fieldName}.dom")
		if year && year != 0 && month && month != 0 && dom && dom != 0
      Date.new(year, month, dom)
    else
      nil
    end
  end

  def getObjId
    getInt("objId")
  end

  def getObjectType (key = "objectType")
  	require 'lafcadio/util/DomainUtil'
		objTypeString = get key
		if (objTypeString && objTypeString != '')
			DomainUtil.getObjectTypeFromString get(key)
		end
  end

	def set (key, value)
		@valueHash.set(key, [value])
	end

	def setDate (dateName, date)
		@valueHash.set( dateName + ".year", [date.year] )
		@valueHash.set (dateName + ".month", [date.month] )
		@valueHash.set (dateName + ".dom", [date.day] )
	end

	def keys
		@valueHash.keys
	end

	def to_hash
		hash = {}
		@valueHash.keys.each { |key| hash[key] = get key }
		hash
	end

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

