require 'date'
require 'lafcadio/dateTime'
require 'lafcadio/util'

module Lafcadio
	# ObjectField is the abstract base class of any field for domain objects.
	class ObjectField
		include Comparable

		attr_reader :name, :object_type
		attr_accessor :not_null, :db_field_name

		def self.instantiate_from_xml( domain_class, fieldElt ) #:nodoc:
			parameters = instantiation_parameters( fieldElt )
			instantiate_with_parameters( domain_class, parameters )
		end

		def self.instantiate_with_parameters( domain_class, parameters ) #:nodoc:
			instance = self.new( domain_class, parameters['name'] )
			if ( db_field_name = parameters['db_field_name'] )
				instance.db_field_name = db_field_name
			end
			instance
		end

		def self.instantiation_parameters( fieldElt ) #:nodoc:
			parameters = {}
			parameters['name'] = fieldElt.attributes['name']
			parameters['db_field_name'] = fieldElt.attributes['db_field_name']
			parameters
		end
		
		def self.value_type #:nodoc:
			Object
		end

		# [object_type]  The domain class that this object field belongs to.
		# [name]        The name of this field.
		def initialize( object_type, name )
			@object_type = object_type
			@name = name
			@db_field_name = name
			@not_null = true
		end
		
		def <=>(other)
			if @object_type == other.object_type && name == other.name
				0
			else
				object_id <=> other.object_id
			end
		end

		def bind_write?; false; end #:nodoc:
		
		def db_table_and_field_name
			"#{ object_type.table_name }.#{ db_field_name }"
		end

		def db_will_automatically_write #:nodoc:
			false
		end

		# Returns the name that this field is referenced by in the MySQL table. By 
		# default this is the same as the name; to override it, set 
		# ObjectField#db_field_name.
		def name_for_sql
			db_field_name
		end

		def prev_value(pk_id) #:nodoc:
			prevObject = ObjectStore.get_object_store.get(@object_type, pk_id)
			prevObject.send(name)
		end

		def process_before_verify(value) #:nodoc:
			value = @default if value == nil
			value
		end

		# Returns a string value suitable for committing this field's value to 
		# MySQL.
		def value_for_sql(value)
			value || 'null'
		end

		def verify(value, pk_id) #:nodoc:
			if value.nil? && not_null
				raise( FieldValueError,
				       "#{ self.object_type.name }##{ name } can not be nil.", caller )
			end
			verify_non_nil( value, pk_id ) if value
		end

		def verify_non_nil( value, pk_id )
			value_type = self.class.value_type
			unless value.class <= value_type
				raise( FieldValueError, 
				       "#{ object_type.name }##{ name } needs a " + value_type.name +
				           " value.",
				       caller )
			end
		end

		# Given the SQL value string, returns a Ruby-native value.
		def value_from_sql(string)
			string
		end
	end

	# IntegerField represents an integer.
	class IntegerField < ObjectField
		def value_from_sql(string) #:nodoc:
			value = super
			value ? value.to_i : nil
		end
	end

	# A TextField is expected to contain a string value.
	class TextField < ObjectField
		def value_for_sql(value) #:nodoc:
			if value
				value = value.gsub(/(\\?')/) { |m| m.length == 1 ? "''" : m }
				value = value.gsub(/\\/) { '\\\\' }
				"'#{value}'"
			else
				"null"
			end
		end
	end

	# BlobField stores a string value and expects to store its value in a BLOB
	# field in the database.
	class BlobField < ObjectField
		attr_accessor :size
		
		def self.value_type; String; end

		def bind_write?; true; end #:nodoc:

		def value_for_sql(value); "?"; end #:nodoc:
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
	#          enum_type="ENUMS_CAPITAL_YES_NO"/>
	# If you're defining a field in Ruby, simply set BooleanField#enum_type to one
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
	# +enums+ takes precedence over +enum_type+.
	class BooleanField < ObjectField
		ENUMS_ONE_ZERO = 0
		ENUMS_CAPITAL_YES_NO = 1

		attr_accessor :enum_type, :enums

		def initialize( object_type, name )
			super( object_type, name )
			@enum_type = ENUMS_ONE_ZERO
			@enums = nil
		end

		def false_enum # :nodoc:
			get_enums[false]
		end

		def get_enums( value = nil ) # :nodoc:
			if @enums
				@enums
			elsif @enum_type == ENUMS_ONE_ZERO
				if value.class == String
					{ true => '1', false => '0' }
				else
					{ true => 1, false => 0 }
				end
			elsif @enum_type == ENUMS_CAPITAL_YES_NO
				{ true => 'Y', false => 'N' }
			else
				raise MissingError
			end
		end

		def text_enum_type # :nodoc:
			@enums ? @enums[true].class == String : @enum_type == ENUMS_CAPITAL_YES_NO
		end

		def true_enum( value = nil ) # :nodoc:
			get_enums( value )[true]
		end

		def value_for_sql(value) # :nodoc:
			if value
				vfs = true_enum
			else
				vfs = false_enum
			end
			text_enum_type ? "'#{vfs}'" : vfs
		end

		def value_from_sql(value, lookupLink = true) # :nodoc:
			value == true_enum( value )
		end
	end

	# DateField represents a Date.
	class DateField < ObjectField
		RANGE_NEAR_FUTURE = 0
		RANGE_PAST = 1

		def self.value_type # :nodoc:
			Date
		end

		attr_accessor :range

		def initialize( object_type, name = "date" )
			super( object_type, name )
			@range = RANGE_NEAR_FUTURE
		end

		def value_for_sql(value) # :nodoc:
			value ? "'#{value.to_s}'" : 'null'
		end

		def value_from_sql(dbiDate, lookupLink = true) # :nodoc:
			begin
				dbiDate ? dbiDate.to_date : nil
			rescue ArgumentError
				nil
			end
		end
	end
	
	# DateTimeField represents a DateTime.
	class DateTimeField < ObjectField
		def value_for_sql(value) # :nodoc:
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

		def value_from_sql(dbi_value, lookupLink = true) # :nodoc:
			dbi_value ? dbi_value.to_time : nil
		end
	end
	
	# DecimalField represents a decimal value.
	class DecimalField < ObjectField
		def self.instantiate_with_parameters( domain_class, parameters ) #:nodoc:
			self.new( domain_class, parameters['name'] )
		end

		def self.value_type #:nodoc:
			Numeric
		end

		def process_before_verify(value) #:nodoc:
			value = super value
			value != nil && value != '' ? value.to_f : nil
		end

		def value_from_sql(string, lookupLink = true) #:nodoc:
			string != nil ? string.to_f : nil
		end
	end

	# EmailField takes a text value that is expected to be formatted as a single
	# valid email address.
	class EmailField < TextField
		# Is +address+ a valid email address?
		def self.valid_address(address)
			address =~ /^[^ @]+@[^ \.]+\.[^ ,]+$/
		end

		def initialize( object_type, name = "email" )
			super( object_type, name )
		end

		def verify_non_nil(value, pk_id) #:nodoc:
			super(value, pk_id)
			if !EmailField.valid_address(value)
				raise( FieldValueError,
				       "#{ object_type.name }##{ name } needs a valid email address.",
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
		def self.instantiate_with_parameters( domain_class, parameters ) #:nodoc:
			self.new( domain_class, parameters['name'], parameters['enums'] )
		end

		def self.enum_queue_hash( fieldElt )
			enumValues = []
			fieldElt.elements.each( 'enums/enum' ) { |enumElt|
				enumValues << enumElt.attributes['key']
				enumValues << enumElt.text.to_s
			}
			QueueHash.new( *enumValues )
		end

		def self.instantiation_parameters( fieldElt ) #:nodoc:
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

		# [object_type]  The domain class that this field belongs to.
		# [name]        The name of this domain class.
		# [enums]       An array of Strings representing the possible choices for
		#               this field.
		def initialize( object_type, name, enums )
			super( object_type, name )
			if enums.class == Array 
				@enums = QueueHash.new_from_array enums
			else
				@enums = enums
			end
		end
		
		def value_for_sql(value) #:nodoc:
			value != '' ?(super(value)) : 'null'
		end
		
		def verify_non_nil( value, pk_id ) #:nodoc:
			super
			if @enums[value].nil?
				key_str = '[ ' +
				          ( @enums.keys.map { |key| "\"#{ key }\"" } ).join(', ') + ' ]'
				err_str = "#{ @object_type.name }##{ name } needs a value that is " +
				          "one of #{ key_str }"
				raise( FieldValueError, err_str, caller )
			end
		end
	end
	
	class FieldValueError < RuntimeError #:nodoc:
	end

	# A LinkField is used to link from one domain class to another.
	class LinkField < ObjectField
		def self.instantiate_with_parameters( domain_class, parameters ) #:nodoc:
			instance = self.new(
				domain_class, parameters['linked_type'], parameters['name'],
				parameters['delete_cascade']
			)
			if parameters['db_field_name']
				instance.db_field_name = parameters['db_field_name']
			end
			instance
		end

		def self.instantiation_parameters( fieldElt ) #:nodoc:
			parameters = super( fieldElt )
			linked_typeStr = fieldElt.attributes['linked_type']
			linked_type = DomainObject.get_object_type_from_string( linked_typeStr )
			parameters['linked_type'] = linked_type
			parameters['delete_cascade'] = fieldElt.attributes['delete_cascade'] == 'y'
			parameters
		end

		attr_reader :linked_type
		attr_accessor :delete_cascade

		# [object_type]    The domain class that this field belongs to.
		# [linked_type]    The domain class that this field points to.
		# [name]          The name of this field.
		# [delete_cascade] If this is true, deleting the domain object that is linked
		#                 to will cause this domain object to be deleted as well.
		def initialize( object_type, linked_type, name = nil,
		                delete_cascade = false )
			unless name
				linked_type.name =~ /::/
				name = $' || linked_type.name
				name = name.decapitalize
			end
			super( object_type, name )
			( @linked_type, @delete_cascade ) = linked_type, delete_cascade
		end

		def value_from_sql(string) #:nodoc:
			string != nil ? DomainObjectProxy.new(@linked_type, string.to_i) : nil
		end

		def value_for_sql(value) #:nodoc:
			if !value
				"null"
			elsif value.pk_id
				value.pk_id
			else
				raise( DomainObjectInitError, "Can't commit #{name} without pk_id", 
				       caller )
			end
		end

		def verify_non_nil(value, pk_id) #:nodoc:
			super
			if @linked_type != @object_type && pk_id
				subsetLinkField = @linked_type.class_fields.find { |field|
					field.class == SubsetLinkField && field.subset_field == @name
				}
				if subsetLinkField
					verify_subset_link_field( subsetLinkField, pk_id )
				end
			end
		end

		def verify_subset_link_field( subsetLinkField, pk_id )
			begin
				prevObj = ObjectStore.get_object_store.get(object_type, pk_id)
				prevObjLinkedTo = prevObj.send(name)
				possiblyMyObj = prevObjLinkedTo.send(subsetLinkField.name)
				if possiblyMyObj && possiblyMyObj.pk_id == pk_id
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
		def self.value_type #:nodoc:
			Month
		end

		def value_for_sql(value) #:nodoc:
			"'#{value.year}-#{value.month}-01'"
		end
	end

	# A PasswordField is simply a TextField that is expected to contain a password
	# value. It can be set to auto-generate a password at random.
	class PasswordField < TextField
		# Returns a random 8-letter alphanumeric password.
		def self.random_password
			chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".
					split(//)
			value = ""
			0.upto(8) { |i| value += chars[rand(chars.size)] }
			value
		end
	end
	
	class PrimaryKeyField < IntegerField
		def initialize( domain_class )
			super( domain_class, 'pk_id' )
			@not_null = false
		end
	end

	# A StateField is a specialized subclass of EnumField; its possible values are
	# any of the 50 states of the United States, stored as each state's two-letter
	# postal code.
	class StateField < EnumField
		def initialize( object_type, name = "state" )
			super( object_type, name, UsStates.states )
		end
	end

	class SubsetLinkField < LinkField #:nodoc:
		def self.instantiate_with_parameters( domain_class, parameters )
			self.new( domain_class, parameters['linked_type'],
			          parameters['subset_field'], parameters['name'] )
		end

		def self.instantiation_parameters( fieldElt )
			parameters = super( fieldElt )
			parameters['subset_field'] = fieldElt.attributes['subset_field']
			parameters
		end
		
		attr_accessor :subset_field

		def initialize( object_type, linked_type, subset_field,
		                name = linked_type.name.downcase )
			super( object_type, linked_type, name )
			@subset_field = subset_field
		end
	end

	# TextListField maps to any String SQL field that tries to represent a 
	# quick-and-dirty list with a comma-separated string. It returns an Array. 
	# For example, a SQL field with the value "john,bill,dave", then the Ruby 
	# field will have the value <tt>[ "john", "bill", "dave" ]</tt>.
	class TextListField < ObjectField
		def self.value_type #:nodoc:
			Array
		end

		def value_for_sql(objectValue) #:nodoc:
			if objectValue.is_a?( Array )
				str = objectValue.join(',')
			else
				str = objectValue
			end
			"'" + str + "'"
		end

		def value_from_sql(sqlString, lookupLink = true) #:nodoc:
			if sqlString
				sqlString.split ','
			else
				[]
			end
		end
	end

	class TimeStampField < DateTimeField #:nodoc:
		def initialize( object_type, name = 'timeStamp' )
			super( object_type, name )
			@not_null = false
		end

		def db_will_automatically_write
			true
		end
	end
end