require 'tempfile'
require 'lafcadio/util/HashOfArrays'
require 'lafcadio/cgi/FieldManager'
require 'lafcadio/objectField/ImageField'

class MockFieldManager < FieldManager
  def initialize(initHash = {})
  	require 'lafcadio/util/DomainUtil'
		@valueHash = HashOfArrays.new
    @imageFields = []
    objTypeString = initHash["objectType"]
    if objTypeString != nil
      objTypeString = objTypeString.read if objTypeString.class == Tempfile
      @objectType = DomainUtil.getObjectTypeFromString objTypeString
      @objectType.classFields.each { |field|
        @imageFields << field.name if field.class == ImageField
      }
    end
    initHash.keys.each { |key|
			value = initHash[key]
			if value.class == Tempfile
#	      value = processTempfile(value, key)
			elsif value.class <= Numeric
				value = value.to_s
			end
			value = [value] unless value.class == Array
			@valueHash.set(key, value)
    }
		if(objectTypeString = get('objectType'))
			@objectType = DomainUtil.getObjectTypeFromString objectTypeString
		end
  end
end
