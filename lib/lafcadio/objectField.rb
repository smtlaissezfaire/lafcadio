require 'date'
require 'lafcadio/dateTime'
require 'lafcadio/util'

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
			"#{ self.objectType.name }##{ name } can not be nil."
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
			verify_non_nil( value, pkId ) if value
		end

		def verify_non_nil( value, pkId )
			valueType = self.class.valueType
			unless value.class <= valueType
				raise( FieldValueError, 
				       "#{ objectType.name }##{ name } needs a " + valueType.name +
				           " value.",
				       caller )
			end
			verifyUniqueness(value, pkId) if unique
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

	# IntegerField represents an integer.
	class IntegerField < ObjectField
		def valueFromSQL(string) #:nodoc:
			value = super
			value ? value.to_i : nil
		end
	end

	# A TextField is expected to contain a string value.
	class TextField < ObjectField
		def valueForSQL(value) #:nodoc:
			if value
				value = value.gsub(/(\\?')/) { |m| m.length == 1 ? "''" : m }
				value = value.gsub(/\\/) { '\\\\' }
				"'#{value}'"
			else
				"null"
			end
		end
	end

	class AutoIncrementField < IntegerField # :nodoc:
		attr_reader :objectType

		def initialize(objectType, name, englishName = nil)
			super(objectType, name, englishName)
			@objectType = objectType
		end

		def HTMLWidgetValueStr(value)
			if value != nil
				super value
			else
				highestValue = 0
				ObjectStore.getObjectStore.getAll(objectType).each { |obj|
					aValue = obj.send(name).to_i
					highestValue = aValue if aValue > highestValue
				}
			 (highestValue + 1).to_s
			end
		end
	end

	# BlobField stores a string value and expects to store its value in a BLOB
	# field in the database.
	class BlobField < ObjectField
		attr_accessor :size
		
		def self.valueType; String; end

		def bind_write?; true; end #:nodoc:

		def valueForSQL(value); "?"; end #:nodoc:
	end

	# BooleanField represents a boolean value. By default, it assumes that the
	# table field represents True and False with the integers 1 and 0. There are
	# two different ways to change this default.
	#
	# First, BooleanField includes a few enumerated defaults. Currently there are
	# only
	#   * BooleanField::ENUMS_ONE_ZERO (the default, uses integers 1 and 0)
	#   * BooleanField::ENUMS_CAPITAL_YES_NO (uses characters 'Y' and 'N')
	# In the XML class definition, this field would look like
	#   <field name="field_name" class="BooleanField"
	#          enumType="ENUMS_CAPITAL_YES_NO"/>
	# If you're defining a field in Ruby, simply set BooleanField#enumType to one
	# of the values.
	#
	# For more fine-grained specification you can pass specific values in. Use
	# this format for the XML class definition:
	#   <field name="field_name" class="BooleanField">
	#     <enums>
	#       <enum key="true">yin</enum>
	#       <enum key="false">tang</enum>
	#     </enums>
	#   </field>
	# If you're defining the field in Ruby, set BooleanField#enums to a hash.
	#   myBooleanField.enums = { true => 'yin', false => 'yang' }
	#
	# +enums+ takes precedence over +enumType+.
	class BooleanField < ObjectField
		ENUMS_ONE_ZERO = 0
		ENUMS_CAPITAL_YES_NO = 1

		attr_accessor :enumType, :enums

		def initialize(objectType, name, englishName = nil)
			super(objectType, name, englishName)
			@enumType = ENUMS_ONE_ZERO
			@enums = nil
		end

		def falseEnum # :nodoc:
			getEnums[false]
		end

		def getEnums( value = nil ) # :nodoc:
			if @enums
				@enums
			elsif @enumType == ENUMS_ONE_ZERO
				if value.class == String
					{ true => '1', false => '0' }
				else
					{ true => 1, false => 0 }
				end
			elsif @enumType == ENUMS_CAPITAL_YES_NO
				{ true => 'Y', false => 'N' }
			else
				raise MissingError
			end
		end

		def textEnumType # :nodoc:
			@enums ? @enums[true].class == String : @enumType == ENUMS_CAPITAL_YES_NO
		end

		def trueEnum( value = nil ) # :nodoc:
			getEnums( value )[true]
		end

		def valueForSQL(value) # :nodoc:
			if value
				vfs = trueEnum
			else
				vfs = falseEnum
			end
			textEnumType ? "'#{vfs}'" : vfs
		end

		def valueFromSQL(value, lookupLink = true) # :nodoc:
			value == trueEnum( value )
		end
	end

	# DateField represents a Date.
	class DateField < ObjectField
		RANGE_NEAR_FUTURE = 0
		RANGE_PAST = 1

		def self.valueType # :nodoc:
			Date
		end

		attr_accessor :range

		def initialize(objectType, name = "date", englishName = nil)
			super(objectType, name, englishName)
			@range = RANGE_NEAR_FUTURE
		end

		def valueForSQL(value) # :nodoc:
			value ? "'#{value.to_s}'" : 'null'
		end

		def valueFromSQL(dbiDate, lookupLink = true) # :nodoc:
			begin
				dbiDate ? dbiDate.to_date : nil
			rescue ArgumentError
				nil
			end
		end
	end
	
	# DateTimeField represents a DateTime.
	class DateTimeField < ObjectField
		def valueForSQL(value) # :nodoc:
			if value
				year = value.year
				month = value.mon.to_s.pad( 2, "0" )
				day = value.day.to_s.pad( 2, "0" )
				hour = value.hour.to_s.pad( 2, "0" )
				minute = value.min.to_s.pad( 2, "0" )
				second = value.sec.to_s.pad( 2, "0" )
				"'#{year}-#{month}-#{day} #{hour}:#{minute}:#{second}'"
			else
				"null"
			end
		end

		def valueFromSQL(dbi_value, lookupLink = true) # :nodoc:
			dbi_value ? dbi_value.to_time : nil
		end
	end
	
	# DecimalField represents a decimal value.
	class DecimalField < ObjectField
		def self.instantiateWithParameters( domainClass, parameters ) #:nodoc:
			self.new( domainClass, parameters['name'], parameters['englishName'] )
		end

		def self.valueType #:nodoc:
			Numeric
		end

		def processBeforeVerify(value) #:nodoc:
			value = super value
			value != nil && value != '' ? value.to_f : nil
		end

		def valueFromSQL(string, lookupLink = true) #:nodoc:
			string != nil ? string.to_f : nil
		end
	end

	# EmailField takes a text value that is expected to be formatted as a single
	# valid email address.
	class EmailField < TextField
		# Is +address+ a valid email address?
		def self.validAddress(address)
			address =~ /^[^ @]+@[^ \.]+\.[^ ,]+$/
		end

		def initialize(objectType, name = "email", englishName = nil)
			super(objectType, name, englishName)
		end

		def nullErrorMsg #:nodoc:
			"Please enter an email address."
		end

		def verify_non_nil(value, pkId) #:nodoc:
			super(value, pkId)
			if !EmailField.validAddress(value)
				raise( FieldValueError,
				       "#{ objectType.name }##{ name } needs a valid email address.",
				       caller )
			end
		end
	end

	# EnumField represents an enumerated field that can only be set to one of a
	# set range of string values. To set the enumeration in the class definition
	# XML, use the following format:
	#   <field name="flavor" class="EnumField">
	#     <enums>
	#       <enum>Vanilla</enum>
	#       <enum>Chocolate</enum>
	#       <enum>Lychee</enum>
	#     </enums>
	#   </field>
	# If you're defining the field in Ruby, you can simply pass in an array of
	# enums as the +enums+ argument.
	#
	class EnumField < TextField
		def self.instantiateWithParameters( domainClass, parameters ) #:nodoc:
			self.new( domainClass, parameters['name'], parameters['enums'],
								parameters['englishName'] )
		end

		def self.enum_queue_hash( fieldElt )
			enumValues = []
			fieldElt.elements.each( 'enums/enum' ) { |enumElt|
				enumValues << enumElt.attributes['key']
				enumValues << enumElt.text.to_s
			}
			QueueHash.new( *enumValues )
		end

		def self.instantiationParameters( fieldElt ) #:nodoc:
			parameters = super( fieldElt )
			if fieldElt.elements['enums'][1].attributes['key']
				parameters['enums'] = enum_queue_hash( fieldElt )
			else
				parameters['enums'] = []
				fieldElt.elements.each( 'enums/enum' ) { |enumElt|
					parameters['enums'] << enumElt.text.to_s
				}
			end
			parameters
		end
		
		attr_reader :enums

		# [objectType]  The domain class that this field belongs to.
		# [name]        The name of this domain class.
		# [enums]       An array of Strings representing the possible choices for
		#               this field.
		# [englishName] The English name of this field. (Deprecated)
		def initialize(objectType, name, enums, englishName = nil)
			super objectType, name, englishName
			if enums.class == Array 
				@enums = QueueHash.newFromArray enums
			else
				@enums = enums
			end
		end
		
		def valueForSQL(value) #:nodoc:
			value != '' ?(super(value)) : 'null'
		end
		
		def verify_non_nil( value, pkId ) #:nodoc:
			super
			if @enums[value].nil?
				key_str = '[ ' +
				          ( @enums.keys.map { |key| "\"#{ key }\"" } ).join(', ') + ' ]'
				err_str = "#{ @objectType.name }##{ name } needs a value that is " +
				          "one of #{ key_str }"
				raise( FieldValueError, err_str, caller )
			end
		end
	end
	
	class FieldValueError < RuntimeError #:nodoc:
	end

	# A LinkField is used to link from one domain class to another.
	class LinkField < ObjectField
		def LinkField.instantiateWithParameters( domainClass, parameters ) #:nodoc:
			self.new( domainClass, parameters['linkedType'], parameters['name'],
								parameters['englishName'], parameters['deleteCascade'] )
		end

		def LinkField.instantiationParameters( fieldElt ) #:nodoc:
			parameters = super( fieldElt )
			linkedTypeStr = fieldElt.attributes['linkedType']
			linkedType = DomainObject.getObjectTypeFromString( linkedTypeStr )
			parameters['linkedType'] = linkedType
			parameters['deleteCascade'] = fieldElt.attributes['deleteCascade'] == 'y'
			parameters
		end

		attr_reader :linkedType
		attr_accessor :deleteCascade

		# [objectType]    The domain class that this field belongs to.
		# [linkedType]    The domain class that this field points to.
		# [name]          The name of this field.
		# [englishName]   The English name of this field. (Deprecated)
		# [deleteCascade] If this is true, deleting the domain object that is linked
		#                 to will cause this domain object to be deleted as well.
		def initialize( objectType, linkedType, name = nil, englishName = nil,
		                deleteCascade = false )
			unless name
				linkedType.name =~ /::/
				name = $' || linkedType.name
				name = name.decapitalize
			end
			super(objectType, name, englishName)
			( @linkedType, @deleteCascade ) = linkedType, deleteCascade
		end

		def valueFromSQL(string) #:nodoc:
			string != nil ? DomainObjectProxy.new(@linkedType, string.to_i) : nil
		end

		def valueForSQL(value) #:nodoc:
			if !value
				"null"
			elsif value.pkId
				value.pkId
			else
				raise( DomainObjectInitError, "Can't commit #{name} without pkId", 
				       caller )
			end
		end

		def verify_non_nil(value, pkId) #:nodoc:
			super
			if @linkedType != @objectType && pkId
				subsetLinkField = @linkedType.classFields.find { |field|
					field.class == SubsetLinkField && field.subsetField == @name
				}
				if subsetLinkField
					verify_subset_link_field( subsetLinkField, pkId )
				end
			end
		end

		def verify_subset_link_field( subsetLinkField, pkId )
			begin
				prevObj = ObjectStore.getObjectStore.get(objectType, pkId)
				prevObjLinkedTo = prevObj.send(name)
				possiblyMyObj = prevObjLinkedTo.send(subsetLinkField.name)
				if possiblyMyObj && possiblyMyObj.pkId == pkId
					cantChangeMsg = "You can't change that."
					raise FieldValueError, cantChangeMsg, caller
				end
			rescue DomainObjectNotFoundError
				# no previous value, so nothing to check for
			end
		end
	end

	class MoneyField < DecimalField #:nodoc:
	end

	# Accepts a Month as a value. This field automatically saves in MySQL as a 
	# date corresponding to the first day of the month.
	class MonthField < DateField
		def self.valueType #:nodoc:
			Month
		end

		def valueForSQL(value) #:nodoc:
			"'#{value.year}-#{value.month}-01'"
		end
	end

	# A PasswordField is simply a TextField that is expected to contain a password
	# value. It can be set to auto-generate a password at random.
	class PasswordField < TextField
		# Returns a random 8-letter alphanumeric password.
		def PasswordField.randomPassword
			chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".
					split(//)
			value = ""
			0.upto(8) { |i| value += chars[rand(chars.size)] }
			value
		end
	end

	# A StateField is a specialized subclass of EnumField; its possible values are
	# any of the 50 states of the United States, stored as each state's two-letter
	# postal code.
	class StateField < EnumField
		def initialize(objectType, name = "state", englishName = nil)
			super objectType, name, UsStates.states, englishName
		end
	end

	class SubsetLinkField < LinkField #:nodoc:
		def self.instantiateWithParameters( domainClass, parameters )
			self.new( domainClass, parameters['linkedType'],
			          parameters['subsetField'], parameters['name'],
								parameters['englishName'] )
		end

		def self.instantiationParameters( fieldElt )
			parameters = super( fieldElt )
			parameters['subsetField'] = fieldElt.attributes['subsetField']
			parameters
		end
		
		attr_accessor :subsetField

		def initialize(objectType, linkedType, subsetField,
				name = linkedType.name.downcase, englishName = nil)
			super(objectType, linkedType, name, englishName)
			@subsetField = subsetField
		end
	end

	# TextListField maps to any String SQL field that tries to represent a 
	# quick-and-dirty list with a comma-separated string. It returns an Array. 
	# For example, a SQL field with the value "john,bill,dave", then the Ruby 
	# field will have the value <tt>[ "john", "bill", "dave" ]</tt>.
	class TextListField < ObjectField
		def self.valueType #:nodoc:
			Array
		end

		def valueForSQL(objectValue) #:nodoc:
			"'" + objectValue.join(',') + "'"
		end

		def valueFromSQL(sqlString, lookupLink = true) #:nodoc:
			if sqlString
				sqlString.split ','
			else
				[]
			end
		end
	end

	class TimeStampField < DateTimeField #:nodoc:
		def initialize(objectType, name = 'timeStamp', englishName = nil)
			super( objectType, name, englishName )
			@notNull = false
		end

		def dbWillAutomaticallyWrite
			true
		end
	end
end