require 'lafcadio/util/English'
require 'lafcadio/objectField/FieldValueError'

module Lafcadio
	class ObjectField
		include Comparable

		attr_reader :name, :defaultFieldName, :objectType
		attr_accessor :notNull, :hideLabel, :writeOnce, :unique, :hideDisplay,
				:default, :dbFieldName, :notUniqueMsg

		def ObjectField.valueType
			Object
		end

		def ObjectField.instantiationParameters( fieldElt )
			parameters = {}
			parameters['name'] = fieldElt.attributes['name']
			parameters['englishName'] = fieldElt.attributes['englishName']
			parameters['dbFieldName'] = fieldElt.attributes['dbFieldName']
			parameters
		end
		
		def ObjectField.instantiateFromXml( domainClass, fieldElt )
			parameters = instantiationParameters( fieldElt )
			instantiateWithParameters( domainClass, parameters )
		end

		def ObjectField.instantiateWithParameters( domainClass, parameters )
			instance = self.new( domainClass, parameters['name'],
			                     parameters['englishName'] )
			if ( dbFieldName = parameters['dbFieldName'] )
				instance.dbFieldName = dbFieldName
			end
			instance
		end

		# [objectType] The domain class that this object field belongs to.
		# [name] The name of this field.
		# [englishName] The descriptive English name of this field.
		def initialize(objectType, name, englishName = nil )
			@objectType = objectType
			@name = name
			@dbFieldName = name
			@notNull = true
			@unique = false
			@default = nil
			@englishNameOrNil = englishName
		end
		
		def bind_write?; false; end
		
		def englishName
			@englishNameOrNil || English.camelCaseToEnglish(name).capitalize
		end

		def nullErrorMsg
			English.sentence "Please enter %a %nam.", englishName.downcase
		end

		def verify(value, pkId)
			if value.nil? && notNull
				raise FieldValueError, nullErrorMsg, caller
			end
			if value
				valueType = self.class.valueType
				unless value.class <= valueType
					raise FieldValueError, 
							"#{name} needs an object of type #{valueType.name}", caller
				end
				verifyUniqueness(value, pkId) if unique
			end
		end

		def verifyUniqueness(value, pkId)
			inferrer = Query::Inferrer.new( @objectType ) { |domain_obj|
				Query.And( domain_obj.send( self.name ).equals( value ),
									 domain_obj.pkId.equals( pkId ).not )
			}
			collisions = ObjectStore.getObjectStore.getSubset( inferrer.execute )
			if collisions.size > 0
				if @notUniqueMsg
					notUniqueMsg = @notUniqueMsg
				else
					notUniqueMsg = "That #{englishName.downcase} is already taken. " +
							"Please choose another."
				end
				raise FieldValueError, notUniqueMsg, caller
			end
		end

		# Returns the name that this field is referenced by in the MySQL table. By 
		# default this is the same as the name; to override it, set 
		# ObjectField#dbFieldName.
		def nameForSQL
			dbFieldName
		end

		# Returns a string value suitable for committing this field's value to 
		# MySQL.
		def valueForSQL(value)
			value || 'null'
		end

		def firstTime(fieldManager)
			pkId = fieldManager.getpkId
			pkId == nil
		end

		def prevValue(pkId)
			prevObject = ObjectStore.getObjectStore.get(@objectType, pkId)
			prevObject.send(name)
		end

		def processBeforeVerify(value)
			value = @default if value == nil
			value
		end

		# Given the SQL value string, returns a Ruby-native value.
		def valueFromSQL(string)
			string
		end

		def <=>(other)
			if @objectType == other.objectType && name == other.name
				0
			else
				id <=> other.id
			end
		end

		def dbWillAutomaticallyWrite
			false
		end
	end
end