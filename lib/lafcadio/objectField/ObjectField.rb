require 'lafcadio/util/English'
require 'lafcadio/objectField'

module Lafcadio
	# ObjectField is the abstract base class of any field for domain objects.
	class ObjectField
		include Comparable

		attr_reader :name, :objectType
		attr_accessor :notNull, :unique, :dbFieldName

		def self.instantiateFromXml( domainClass, fieldElt ) #:nodoc:
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

		def self.instantiationParameters( fieldElt ) #:nodoc:
			parameters = {}
			parameters['name'] = fieldElt.attributes['name']
			parameters['englishName'] = fieldElt.attributes['englishName']
			parameters['dbFieldName'] = fieldElt.attributes['dbFieldName']
			parameters
		end
		
		def self.valueType #:nodoc:
			Object
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
			@englishNameOrNil = englishName
		end
		
		def <=>(other)
			if @objectType == other.objectType && name == other.name
				0
			else
				object_id <=> other.object_id
			end
		end

		def bind_write?; false; end #:nodoc:
		
		def db_table_and_field_name
			"#{ objectType.tableName }.#{ dbFieldName }"
		end

		def dbWillAutomaticallyWrite #:nodoc:
			false
		end

		def englishName #:nodoc:
			@englishNameOrNil || English.camelCaseToEnglish(name).capitalize
		end

		# Returns the name that this field is referenced by in the MySQL table. By 
		# default this is the same as the name; to override it, set 
		# ObjectField#dbFieldName.
		def nameForSQL
			dbFieldName
		end

		def nullErrorMsg #:nodoc:
			English.sentence "Please enter %a %nam.", englishName.downcase
		end

		def prevValue(pkId) #:nodoc:
			prevObject = ObjectStore.getObjectStore.get(@objectType, pkId)
			prevObject.send(name)
		end

		def processBeforeVerify(value) #:nodoc:
			value = @default if value == nil
			value
		end

		# Returns a string value suitable for committing this field's value to 
		# MySQL.
		def valueForSQL(value)
			value || 'null'
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
				notUniqueMsg = "That #{englishName.downcase} already exists."
				raise FieldValueError, notUniqueMsg, caller
			end
		end

		# Given the SQL value string, returns a Ruby-native value.
		def valueFromSQL(string)
			string
		end
	end
end