require 'date'
require 'lafcadio/depend'
require 'lafcadio/util'

module Lafcadio
	# ObjectField is the abstract base class of any field for domain objects.
	# Fields can be added to a domain class using DomainObject.string,
	# DomainObject.integer, etc.
	#
	#   class User < Lafcadio::DomainObject
	#     string 'fname'
	#     date   'birthday'
	#   end
	#
	# All fields accept the following arguments in hashes:
	# [not_nil]        This is +true+ by default. Set it to +false+ to avoid
	#                  checking for nil values in tests.
	# [db_field_name]  By default, fields are assumed to have the same name in
	#                  the database, but you can override this assumption using
	#                  +db_field_name+.
	#
	#   class User < Lafcadio::DomainObject
	#     string 'fname', { 'not_nil' => false }
	#     date   'birthday', { 'db_field_name' => 'bday' }
	#   end
	class ObjectField
		def self.create_from_xml( domain_class, fieldElt ) #:nodoc:
			parameters = creation_parameters( fieldElt )
			create_with_args( domain_class, parameters )
		end

		def self.create_with_args( domain_class, parameters ) #:nodoc:
			instance = self.new( domain_class, parameters['name'] )
			if ( db_field_name = parameters['db_field_name'] )
				instance.db_field_name = db_field_name
			end
			instance
		end

		def self.creation_parameters( fieldElt ) #:nodoc:
			parameters = {}
			parameters['name'] = fieldElt.attributes['name']
			parameters['db_field_name'] = fieldElt.attributes['db_field_name']
			parameters
		end
		
		def self.value_type #:nodoc:
			Object
		end

		include Comparable

		attr_reader :domain_class, :name
		attr_accessor :db_field_name, :not_nil

		# [domain_class]  The domain class that this field belongs to.
		# [name]          The name of this field.
		def initialize( domain_class, name )
			@domain_class = domain_class
			@name = name
			@db_field_name = name
			@not_nil = true
		end
		
		def <=>(other)
			if @domain_class == other.domain_class && name == other.name
				0
			else
				object_id <=> other.object_id
			end
		end

		def bind_write? #:nodoc:
			false
		end
		
		def db_column #:nodoc:
			"#{ domain_class.table_name }.#{ db_field_name }"
		end

		def db_will_automatically_write? #:nodoc:
			false
		end

		def prev_value(pk_id) #:nodoc:
			prevObject = ObjectStore.get_object_store.get( @domain_class, pk_id )
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
			if value.nil? && not_nil
				raise(
					FieldValueError,
					"#{ self.domain_class.name }##{ name } can not be nil.",
					caller
				)
			end
			verify_non_nil_value( value, pk_id ) if value
		end

		def verify_non_nil_value( value, pk_id ) #:nodoc:
			value_type = self.class.value_type
			unless value.class <= value_type
				raise(
					FieldValueError, 
					"#{ domain_class.name }##{ name } needs a " + value_type.name +
				           " value.",
					caller
				)
			end
		end

		# Given the SQL value string, returns a Ruby-native value.
		def value_from_sql(string)
			string
		end
	end

	# A StringField is expected to contain a string value.
	class StringField < ObjectField
		def value_for_sql(value)
			if value
				value = value.gsub(/(\\?')/) { |m| m.length == 1 ? "''" : m }
				value = value.gsub(/\\/) { '\\\\' }
				"'#{value}'"
			else
				"null"
			end
		end
	end

	# IntegerField represents an integer.
	class IntegerField < ObjectField
		def value_from_sql(string)
			value = super
			value ? value.to_i : nil
		end
	end

	# BlobField stores a string value and expects to store its value in a BLOB
	# field in the database.
	class BlobField < ObjectField
		def self.value_type #:nodoc:
			String
		end

		def bind_write?; true; end #:nodoc:

		def value_for_sql(value); "?"; end
	end

	# BooleanField represents a boolean value. By default, it assumes that the
	# table field represents +true+ and +false+ with the integers 1 and 0. There
	# are two different ways to change this default.
	#
	# First, BooleanField includes a few enumerated defaults. Currently there are
	# only
	#   * :one_zero (the default, uses integers 1 and 0)
	#   * :capital_yes_no (uses characters 'Y' and 'N')
	# In a class definition, this would look like
	#   class User < Lafcadio::DomainObject
	#     boolean 'administrator', { 'enum_type' => :capital_yes_no }
	#   end
	#
	# For more fine-grained specification you can pass a hash with the keys
	# +true+ and +false+ using the argument +enums+.
	#   class User < Lafcadio::DomainObject
	#     boolean 'administrator',
	#             { 'enums' => { true => 'yin', false => 'yang' } }
	#   end
	# +enums+ takes precedence over +enum_type+.
	class BooleanField < ObjectField
		attr_accessor :enum_type
		attr_writer   :enums

		def initialize( domain_class, name )
			super( domain_class, name )
			@enum_type = :one_zero
			@enums = nil
		end

		def enums( value = nil ) # :nodoc:
			if @enums
				@enums
			elsif @enum_type == :one_zero
				if value.is_a?( String )
					{ true => '1', false => '0' }
				else
					{ true => 1, false => 0 }
				end
			elsif @enum_type == :capital_yes_no
				{ true => 'Y', false => 'N' }
			else
				raise MissingError
			end
		end

		def false_enum # :nodoc:
			enums[false]
		end

		def text_enum_type? # :nodoc:
			@enums ? @enums[true].class == String : @enum_type == :capital_yes_no
		end

		def true_enum( value = nil ) # :nodoc:
			enums( value )[true]
		end

		def value_for_sql(value) # :nodoc:
			vfs = value ? true_enum : false_enum
			text_enum_type? ? "'#{ vfs }'" : vfs
		end

		def value_from_sql( value ) # :nodoc:
			value == true_enum( value )
		end
	end

	# DateField represents a Date.
	class DateField < ObjectField
		def self.value_type # :nodoc:
			Date
		end

		def initialize( domain_class, name = "date" )
			super( domain_class, name )
		end

		def value_for_sql(value) # :nodoc:
			value ? "'#{value.to_s}'" : 'null'
		end

		def value_from_sql( dbiDate ) # :nodoc:
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

		def value_from_sql( dbi_value ) # :nodoc:
			dbi_value ? dbi_value.to_time : nil
		end
	end

	# A DomainObjectField is used to link from one domain class to another. To
	# add such an association in a class definition, call
	# DomainObject.domain_object:
	#   class Invoice < Lafcadio::DomainObject
	#     domain_object Client
	#   end
	# By default, the field name is assumed to be the same as the class name,
	# only lower-cased and camel-case.
	#   class LineItem < Lafcadio::DomainObject
	#     domain_object Product         # field name 'product'
	#     domain_object CatalogOrder    # field name 'catalog_order'
	#   end
	# The field name can be explicitly set as the 2nd argument of
	# DomainObject.domain_object.
	#   class Message < Lafcadio::DomainObject
	#     domain_object User, 'sender'
	#     domain_object User, 'recipient'
	#   end
	# Setting +delete_cascade+ to true means that if the domain object being
	# associated to is deleted, this domain object will also be deleted.
	#   class Invoice < Lafcadio::DomainObject
	#     domain_object Client, 'client', { 'delete_cascade' => true }
	#   end
	#   cli = Client.new( 'name' => 'big company' ).commit
	#   inv = Invoice.new( 'client' => cli ).commit
	#   cli.delete!
	#   inv_prime = Invoice[inv.pk_id] # => will raise DomainObjectNotFoundError
	class DomainObjectField < ObjectField
		def self.auto_name( linked_type ) #:nodoc:
			linked_type.basename.camel_case_to_underscore
		end

		def self.create_with_args( domain_class, parameters ) #:nodoc:
			linked_type = parameters['linked_type']
			instance = self.new(
				domain_class, linked_type,
				parameters['name'] || auto_name( linked_type ),
				parameters['delete_cascade']
			)
			if parameters['db_field_name']
				instance.db_field_name = parameters['db_field_name']
			end
			instance
		end

		def self.creation_parameters( fieldElt ) #:nodoc:
			parameters = super( fieldElt )
			linked_typeStr = fieldElt.attributes['linked_type']
			parameters['linked_type'] = Class.by_name linked_typeStr
			parameters['delete_cascade'] = 
					( fieldElt.attributes['delete_cascade'] == 'y' )
			parameters
		end

		attr_reader :linked_type
		attr_accessor :delete_cascade

		def initialize( domain_class, linked_type, name = nil,
		                delete_cascade = false ) #:nodoc:
			name = self.class.auto_name( linked_type ) unless name
			super( domain_class, name )
			( @linked_type, @delete_cascade ) = linked_type, delete_cascade
		end

		def value_for_sql(value) #:nodoc:
			if value.nil?
				"null"
			elsif value.pk_id
				value.pk_id
			else
				raise(
					DomainObjectInitError, "Can't commit #{name} without pk_id", caller
				)
			end
		end

		def value_from_sql(string) #:nodoc:
			string ? DomainObjectProxy.new(@linked_type, string.to_i) : nil
		end

		def verify_non_nil_value(value, pk_id) #:nodoc:
			super
			if @linked_type != @domain_class && pk_id
				subsetDomainObjectField = @linked_type.class_fields.find { |field|
					field.is_a?( SubsetDomainObjectField ) && field.subset_field == @name
				}
				if subsetDomainObjectField
					verify_subset_link_field( subsetDomainObjectField, pk_id )
				end
			end
		end

		def verify_subset_link_field( subsetDomainObjectField, pk_id ) #:nodoc:
			begin
				prevObjLinkedTo = domain_class[pk_id].send(name)
				possiblyMyObj = prevObjLinkedTo.send subsetDomainObjectField.name
				if possiblyMyObj && possiblyMyObj.pk_id == pk_id
					cantChangeMsg = "You can't change that."
					raise FieldValueError, cantChangeMsg, caller
				end
			rescue DomainObjectNotFoundError
				# no previous value, so nothing to check for
			end
		end
	end

	# EmailField takes a text value that is expected to be formatted as a single
	# valid email address.
	class EmailField < StringField
		# Is +address+ a valid email address?
		def self.valid_address(address)
			address =~ /^[^ @]+@[^ \.]+\.[^ ,]+$/
		end

		def initialize( domain_class, name = "email" )
			super( domain_class, name )
		end

		def verify_non_nil_value(value, pk_id) #:nodoc:
			super(value, pk_id)
			if !EmailField.valid_address(value)
				raise(
					FieldValueError,
				  "#{ domain_class.name }##{ name } needs a valid email address.",
				  caller
				)
			end
		end
	end

	# EnumField represents an enumerated field that can only be set to one of a
	# set range of string values. To set the enumeration in the class definition,
	# pass in an Array of values as +enums+.
	#   class IceCream < Lafcadio::DomainObject
	#     enum 'flavor', { 'enums' => %w( Vanilla Chocolate Lychee ) }
	#   end
	class EnumField < StringField
		def self.create_with_args( domain_class, parameters ) #:nodoc:
			self.new( domain_class, parameters['name'], parameters['enums'] )
		end

		def self.enum_queue_hash( fieldElt ) #:nodoc:
			enumValues = []
			fieldElt.elements.each( 'enums/enum' ) { |enumElt|
				enumValues << enumElt.attributes['key']
				enumValues << enumElt.text.to_s
			}
			QueueHash.new( *enumValues )
		end

		def self.creation_parameters( fieldElt ) #:nodoc:
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

		def initialize( domain_class, name, enums ) #:nodoc:
			super( domain_class, name )
			if enums.class == Array 
				@enums = QueueHash.new_from_array enums
			else
				@enums = enums
			end
		end
		
		def value_for_sql(value) #:nodoc:
			value != '' ? (super(value)) : 'null'
		end
		
		def verify_non_nil_value( value, pk_id ) #:nodoc:
			super
			if @enums[value].nil?
				key_str = '[ ' +
				          ( @enums.keys.map { |key| "\"#{ key }\"" } ).join(', ') + ' ]'
				err_str = "#{ @domain_class.name }##{ name } needs a value that is " +
				          "one of #{ key_str }"
				raise( FieldValueError, err_str, caller )
			end
		end
	end
	
	class FieldValueError < RuntimeError #:nodoc:
	end

	# FloatField represents a decimal value.
	class FloatField < ObjectField
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

	class PrimaryKeyField < IntegerField #:nodoc:
		def initialize( domain_class )
			super( domain_class, 'pk_id' )
			@not_nil = false
		end
	end

	# A StateField is a specialized subclass of EnumField; its possible value
	# are any of the 50 states of the United States, stored as each state's
	# two-letter postal code.
	class StateField < EnumField
		def initialize( domain_class, name = "state" )
			super( domain_class, name, USCommerce::UsStates.states )
		end
	end

	class SubsetDomainObjectField < DomainObjectField #:nodoc:
		def self.create_with_args( domain_class, parameters )
			self.new( domain_class, parameters['linked_type'],
			          parameters['subset_field'], parameters['name'] )
		end

		def self.creation_parameters( fieldElt )
			parameters = super( fieldElt )
			parameters['subset_field'] = fieldElt.attributes['subset_field']
			parameters
		end
		
		attr_accessor :subset_field

		def initialize( domain_class, linked_type, subset_field,
		                name = linked_type.name.downcase )
			super( domain_class, linked_type, name )
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
		def initialize( domain_class, name = 'timeStamp' )
			super( domain_class, name )
			@not_nil = false
		end

		def db_will_automatically_write?
			true
		end
	end
end