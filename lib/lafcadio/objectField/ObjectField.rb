require 'lafcadio/util/English'
require 'lafcadio/objectField/FieldValueError'

module Lafcadio
	# ObjectField is the abstract base class of any field for domain objects.
	class ObjectField
		include Comparable

		attr_reader :name, :defaultFieldName, :objectType
		attr_accessor :notNull, :hideLabel, :writeOnce, :unique, :hideDisplay,
				:default, :dbFieldName, :notUniqueMsg

		def ObjectField.valueType #:nodoc:
			Object
		end

		def ObjectField.instantiationParameters( fieldElt ) #:nodoc:
			parameters = {}
			parameters['name'] = fieldElt.attributes['name']
			parameters['englishName'] = fieldElt.attributes['englishName']
			parameters['dbFieldName'] = fieldElt.attributes['dbFieldName']
			parameters
		end
		
		def ObjectField.instantiateFromXml( domainClass, fieldElt ) #:nodoc:
			parameters = instantiationParameters( fieldElt )
			instantiateWithParameters( domainClass, parameters )
		end

		def self.instantiateWithParameters( domainClass, parameters ) #:nodoc:
			instance = self.new( domainClass, parameters['name'],
			                     parameters['englishName'] )
			if ( dbFieldName = parameters['dbFieldName'] )
				instance.dbFieldName = dbFieldName
			end
			instance
		end

		# [objectType]  The domain class that this object field belongs to.
		# [name]        The name of this field.
		# [englishName] The descriptive English name of this field. (Deprecated)
		def initialize(objectType, name, englishName = nil )
			@objectType = objectType
			@name = name
			@dbFieldName = name
			@notNull = true
			@unique = false
			( @default, @notUniqueMsg ) = [ nil, nil ]
			@englishNameOrNil = englishName
		end
		
		def bind_write?; false; end #:nodoc:
		
		def englishName #:nodoc:
			@englishNameOrNil || English.camelCaseToEnglish(name).capitalize
		end

		def nullErrorMsg #:nodoc:
			English.sentence "Please enter %a %nam.", englishName.downcase
		end

		def verify(value, pkId) #:nodoc:
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

		def verifyUniqueness(value, pkId) #:nodoc:
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

		def firstTime(fieldManager) #:nodoc:
			pkId = fieldManager.getpkId
			pkId == nil
		end

		def prevValue(pkId) #:nodoc:
			prevObject = ObjectStore.getObjectStore.get(@objectType, pkId)
			prevObject.send(name)
		end

		def processBeforeVerify(value) #:nodoc:
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
				object_id <=> other.object_id
			end
		end

		def dbWillAutomaticallyWrite #:nodoc:
			false
		end
	end
end