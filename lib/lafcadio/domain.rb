require 'lafcadio/objectField'
require 'lafcadio/util'
require 'rexml/document'

module Lafcadio
	class ClassDefinitionXmlParser # :nodoc: all
		def initialize( domainClass, xml )
			@domainClass = domainClass
			@xmlDocRoot = REXML::Document.new( xml ).root
			@namesProcessed = {}
		end
		
		def get_class_field( fieldElt )
			className = fieldElt.attributes['class'].to_s
			name = fieldElt.attributes['name']
			begin
				fieldClass = Class.getClass( 'Lafcadio::' + className )
				register_name( name )
				field = fieldClass.instantiateFromXml( @domainClass, fieldElt )
				set_field_attributes( field, fieldElt )
			rescue MissingError
				msg = "Couldn't find field class '#{ className }' for field " +
				      "'#{ name }'"
				raise( MissingError, msg, caller )
			end
			field
		end

		def get_class_fields
			namesProcessed = {}
			fields = []
			@xmlDocRoot.elements.each('field') { |fieldElt|
				fields << get_class_field( fieldElt )
			}
			fields
		end
		
		def possible_field_attributes
			fieldAttr = []
			fieldAttr << FieldAttribute.new( 'size', FieldAttribute::INTEGER )
			fieldAttr << FieldAttribute.new( 'unique', FieldAttribute::BOOLEAN )
			fieldAttr << FieldAttribute.new( 'notNull', FieldAttribute::BOOLEAN )
			fieldAttr << FieldAttribute.new( 'enumType', FieldAttribute::ENUM,
																			 BooleanField )
			fieldAttr << FieldAttribute.new( 'enums', FieldAttribute::HASH )
			fieldAttr << FieldAttribute.new( 'range', FieldAttribute::ENUM,
																			 DateField )
			fieldAttr << FieldAttribute.new( 'large', FieldAttribute::BOOLEAN )
		end

		def register_name( name )
			raise InvalidDataError if @namesProcessed[name]
			@namesProcessed[name] = true
		end
		
		def set_field_attributes( field, fieldElt )
			possible_field_attributes.each { |fieldAttr|
				fieldAttr.maybe_set_field_attr( field, fieldElt )
			}
		end

		def sql_primary_key_name
			@xmlDocRoot.attributes['sql_primary_key_name']
		end
		
		def table_name
			@xmlDocRoot.attributes['table_name']
		end
		
		class FieldAttribute
			INTEGER = 1
			BOOLEAN = 2
			ENUM    = 3
			HASH    = 4
			
			attr_reader :name, :valueClass
		
			def initialize( name, valueClass, objectFieldClass = nil )
				@name = name; @valueClass = valueClass
				@objectFieldClass = objectFieldClass
			end
			
			def maybe_set_field_attr( field, fieldElt )
				setterMethod = "#{ name }="
				if field.respond_to?( setterMethod )
					if valueClass != FieldAttribute::HASH
						if ( attrStr = fieldElt.attributes[name] )
							field.send( setterMethod, value_from_string( attrStr ) )
						end
					else
						if ( attrElt = fieldElt.elements[name] )
							field.send( setterMethod, value_from_elt( attrElt ) )
						end
					end
				end
			end

			def value_from_elt( elt )
				hash = {}
				elt.elements.each( English.singular( @name ) ) { |subElt|
					key = subElt.attributes['key'] == 'true'
					value = subElt.text.to_s
					hash[key] = value
				}
				hash
			end
			
			def value_from_string( valueStr )
				if @valueClass == INTEGER
					valueStr.to_i
				elsif @valueClass == BOOLEAN
					valueStr == 'y'
				elsif @valueClass == ENUM
					eval "#{ @objectFieldClass.name }::#{ valueStr }"
				end
			end
		end

		class InvalidDataError < ArgumentError; end
	end

	module DomainComparable
		include Comparable

		# A DomainObject or DomainObjectProxy is compared by +object_type+ and by
		# +pkId+. 
		def <=>(anOther)
			if anOther.respond_to?( 'object_type' )
				if self.object_type == anOther.object_type
					self.pkId <=> anOther.pkId
				else
					self.object_type.name <=> anOther.object_type.name
				end
			else
				nil
			end
		end
		
		def eql?(otherObj)
			self == otherObj
		end

		def hash; "#{ self.class.name } #{ pkId }".hash; end
	end

	# All classes that correspond to a table in the database need to be children 
	# of DomainObject.
	#
	# = Defining fields
	# There are two ways to define the fields of a DomainObject subclass.
	# 1. Defining fields in an XML file. To do this,
	#    1. Set one directory to contain all your XML files, by setting
	#       +classDefinitionDir+ in your LafcadioConfig file.
	#    2. Write one XML file per domain class. For example, a User.xml file
	#       might look like:
	#         <lafcadio_class_definition name="User">
	#           <field name="lastName" class="TextField"/>
	#           <field name="email" class="TextField"/>
	#           <field name="password" class="TextField"/>
	#           <field name="birthday" class="DateField"/>
	#         </lafcadio_class_definition>
	# 2. Overriding DomainObject.get_class_fields. The method should return an Array
	#    of instances of ObjectField or its children. The order is unimportant.
	#    For example:
	#      class User < DomainObject 
	#        def User.get_class_fields 
	#          fields = [] 
	#          fields << TextField.new(self, 'firstName') 
	#          fields << TextField.new(self, 'lastName') 
	#          fields << TextField.new(self, 'email') 
	#          fields << TextField.new(self, 'password') 
	#          fields << DateField.new(self, 'birthday') 
	#          fields 
	#        end 
	#      end
	#
	# = Setting and retrieving fields
	# Once your fields are defined, you can create an instance by passing in a
	# hash of field names and values.
	#   john = User.new( 'firstName' => 'John', 'lastName' => 'Doe',
	#                    'email' => 'john.doe@email.com',
	#                    'password' => 'my_password',
	#                    'birthday' => tenYearsAgo )
	#
	# You can read and write these fields like normal instance attributes.
	#   john.email => 'john.doe@email.com'
	#   john.email = 'john.doe@mail.email.com'
	#
	# If your domain class has fields that refer to other domain classes, or even
	# to another row in the same table, you can use a LinkField to express the
	# relation.
	#   <lafcadio_class_definition name="Message">
	#     <field name="subject" class="TextField" />
	#     <field name="body" class="TextField" />
	#     <field name="author" class="LinkField" linkedType="User" />
	#     <field name="recipient" class="LinkField" linkedType="User" />
	#     <field name="dateSent" class="DateField" />
	#   </lafcadio_class_definition>
 	#
 	#   msg = Message.new( 'subject' => 'hi there',
 	#                      'body' => 'You wanna go to the movies on Saturday?',
 	#                      'author' => john, 'recipient' => jane,
 	#                      'dateSent' => Date.today )
	#
	# = pkId and committing
	# Lafcadio requires that each table has a numeric primary key. It assumes that
	# this key is named +pkId+ in the database, though that can be overridden.
	#
	# When you create a domain object by calling new, you should not assign a
	# +pkId+ to the new instance. The pkId will automatically be set when you
	# commit the object by calling DomainObject#commit.
	#
	# However, you may want to manually set +pkId+ when setting up a test case, so
	# you can ensure that a domain object has a given primary key.
	#
	# = Naming assumptions, and how to override them
	# By default, Lafcadio assumes that every domain object is indexed by the
	# field +pkId+ in the database schema. If you're dealing with a table that 
	# uses a different field name, override DomainObject.sql_primary_key_name.
	# However, you will always use +pkId+ in your Ruby code.
	#
	# Lafcadio assumes that a domain class corresponds to a table whose name is 
	# the plural of the class name, and whose first letter is lowercase. A User 
	# class is assumed to be stored in a "users" table, while a ProductCategory 
	# class is assumed to be stored in a "productCategories" table. Override
	# DomainObject.table_name to override this behavior.
	#
	# = Inheritance
	# Domain classes can inherit from other domain classes; they have all the 
	# fields of any concrete superclasses plus any new fields defined for 
	# themselves. You can use normal inheritance to define this:
	#   class User < DomainObject
	#     ...
	#   end
	#
	#   class Administrator < User
	#     ...
	#   end
	#
	# Lafcadio assumes that each concrete class has a corresponding table, and
	# that each table has a +pkId+ field that is used to match rows between
	# different levels.
	class DomainObject
		@@subclassHash = {}
		@@class_fields = {}

		COMMIT_ADD = 1
		COMMIT_EDIT = 2
		COMMIT_DELETE = 3

		include DomainComparable
		
		def self.abstract_subclasses #:nodoc:
			require 'lafcadio/domain'
			[ MapObject ]
		end

		# Returns an array of all fields defined for this class and all concrete
		# superclasses.
		def DomainObject.allFields
			allFields = []
			selfAndConcreteSuperclasses.each { |aClass|
				aClass.class_fields.each { |field| allFields << field }
			}
			allFields
		end

		def self.class_fields #:nodoc:
			class_fields = @@class_fields[self]
			unless class_fields
				@@class_fields[self] = self.get_class_fields
				class_fields = @@class_fields[self]
			end
			class_fields
		end

		def self.create_field( field_class, name, att_hash )
			class_fields = @@class_fields[self]
			if class_fields.nil?
				class_fields = []
				@@class_fields[self] = class_fields
			end
			att_hash['name'] = name
			field = field_class.instantiateWithParameters( self, att_hash )
			att_hash.each { |field_name, value|
				setter = field_name + '='
				field.send( setter, value ) if field.respond_to?( setter )
			}
			class_fields << field
		end
		
		def self.dependent_classes #:nodoc:
			dependent_classes = {}
			DomainObject.subclasses.each { |aClass|
				if aClass != DomainObjectProxy &&
						(!DomainObject.abstract_subclasses.index(aClass))
					aClass.class_fields.each { |field|
						if field.class <= LinkField && field.linkedType == self.object_type
							dependent_classes[aClass] = field
						end
					}
				end
			}
			dependent_classes
		end

		def self.get_class_field(fieldName) #:nodoc:
			field = nil
			self.class_fields.each { |aField|
				field = aField if aField.name == fieldName
			}
			field
		end
		
		def self.get_domain_dirs #:nodoc:
			config = LafcadioConfig.new
			classPath = config['classpath']
			domainDirStr = config['domainDirs']
			if domainDirStr
				domainDirs = domainDirStr.split(',')
			else
				domainDirs = [ classPath + 'domain/' ]
			end
		end
		
		def self.get_field( fieldName ) #:nodoc:
			aDomainClass = self
			field = nil
			while aDomainClass < DomainObject && !field
				field = aDomainClass.get_class_field( fieldName )
				aDomainClass = aDomainClass.superclass
			end
			if field
				field
			else
				errStr = "Couldn't find field \"#{ field }\" in " +
								 "#{ self } domain class"
				raise( MissingError, errStr, caller )
			end
		end

		def self.get_object_type_from_string(typeString) #:nodoc:
			object_type = nil
			requireDomainFile( typeString )
			subclasses.each { |subclass|
				object_type = subclass if subclass.to_s == typeString
			}
			if object_type
				object_type
			else
				raise CouldntMatchObjectTypeError,
						"couldn't match object_type #{typeString}", caller
			end
		end

		def self.inherited(subclass) #:nodoc:
			@@subclassHash[subclass] = true
		end
		
		def self.is_based_on? #:nodoc:
		  self.superclass.is_concrete?
		end

		def self.is_concrete? #:nodoc:
		  (self != DomainObject && abstract_subclasses.index(self).nil?)
		end

		def self.method_missing( methodId, *args ) #:nodoc:
			method_name = methodId.id2name
			maybe_field_class_name = ( method_name.gsub( /^(.)/ ) { $&.upcase } ) +
			                         'Field'
			begin
				field_class = Lafcadio.const_get( maybe_field_class_name )
				create_field( field_class, args[0], args[1] || {} )
			rescue NameError
				ObjectType.getObjectType( self ).send( method_name, *args )
			end
		end

		def self.object_type #:nodoc:
			self
		end

		def self.requireDomainFile( typeString )
			typeString =~ /([^\:]*)$/
			fileName = $1
			get_domain_dirs.each { |domainDir|
				if Dir.entries(domainDir).index("#{fileName}.rb")
					require "#{ domainDir }#{ fileName }"
				end
			}
			if (domainFilesStr = LafcadioConfig.new['domainFiles'])
				domainFilesStr.split(',').each { |domainFile|
					require domainFile
				}
			end
		end

		def self.selfAndConcreteSuperclasses # :nodoc:
			classes = [ ]
			anObjectType = self
			until(anObjectType == DomainObject ||
					abstract_subclasses.index(anObjectType) != nil)
				classes << anObjectType
				anObjectType = anObjectType.superclass
			end
			classes
		end

		def self.subclasses #:nodoc:
			@@subclassHash.keys
		end

		attr_accessor :errorMessages, :pkId, :lastCommit, :fields, :fields_set
		attr_reader :delete
		protected :fields, :fields_set

		# fieldHash should contain key-value associations for the different
		# fields of this domain class. For example, instantiating a User class 
		# might look like:
		#
		#   User.new( 'firstNames' => 'John', 'lastName' => 'Doe',
		#             'email' => 'john.doe@email.com', 'password' => 'l33t' )
		#
		# In normal usage any code you write that creates a domain object will not
		# define the +pkId+ field. The system assumes that a domain object with an
		# undefined +pkId+ has yet to be inserted into the database, and when you
		# commit the domain object a +pkId+ will automatically be assigned.
		#
		# If you're creating mock objects for unit tests, you can explicitly set 
		# the +pkId+ to represent objects that already exist in the database.
		def initialize(fieldHash)
			@fieldHash = fieldHash
			@pkId = fieldHash['pkId']
			@pkId = @pkId.to_i unless @pkId.nil?
			@errorMessages = []
			@fields = {}
			@fields_set = []
			check_fields = LafcadioConfig.new()['checkFields']
			verify if %w( onInstantiate onAllStates ).include?( check_fields )
		end
		
		# Returns a clone, with all of the fields copied.
		def clone
			copy = super
			copy.fields = @fields.clone
			copy.fields_set = @fields_set.clone
			copy
		end
		
		# Commits this domain object to the database.
		def commit
			ObjectStore.get_object_store.commit self
		end

		# Set the delete value to true if you want this domain object to be deleted
		# from the database during its next commit.
		def delete=(value)
			if value && !pkId
				raise "No point deleting an object that's not already in the DB"
			end
			@delete = value
		end

		def get_field( field ) #:nodoc:
			unless @fields_set.include?( field )
				set_field( field, @fieldHash[field.name] )
			end
			@fields[field.name]
		end
		
		def get_getter_field( methId ) #:nodoc:
			begin
				self.class.get_field( methId.id2name )
			rescue MissingError
				nil
			end
		end

		def get_setter_field( methId ) #:nodoc:
			if methId.id2name =~ /(.*)=$/
				begin
					self.class.get_field( $1 )
				rescue MissingError
					nil
				end
			else
				nil
			end
		end
		
		def method_missing( methId, *args ) #:nodoc:
			if ( field = get_setter_field( methId ) )
				set_field( field, args.first )
			elsif ( field = get_getter_field( methId ) )
				get_field( field )
			else
				super( methId, *args )
			end
		end

		# Returns the subclass of DomainObject that this instance represents.
		# Because of the way that proxying works, clients should call this method
		# instead of Object.class.
		def object_type
			self.class.object_type
		end

		# This template method is called before every commit. Subclasses can 
		# override it to ensure code is executed before a commit.
		def preCommitTrigger
			nil
		end

		# This template method is called after every commit. Subclasses can 
		# override it to ensure code is executed after a commit.
		def postCommitTrigger
			nil
		end

		def set_field( field, value ) #:nodoc:
			if field.class <= LinkField
				if value.class != DomainObjectProxy && value
					value = DomainObjectProxy.new(value)
				end
			end
			if LafcadioConfig.new()['checkFields'] == 'onAllStates'
				field.verify( value, pkId )
			end
			@fields[field.name] = value
			@fields_set << field
		end
		
		def verify
			self.class.get_class_fields.each { |field|
				field.verify( self.send( field.name ), self.pkId )
			}
		end
	end

	# Any domain class that is used mostly to map between two other domain 
	# classes should be a subclass of MapObject. Subclasses of MapObject should 
	# override MapObject.mappedTypes, returning a two-element array containing 
	# the domain classes that the map object maps between.
	class MapObject < DomainObject
		def self.otherMappedType(firstType) #:nodoc:
			types = mappedTypes
			if types.index(firstType) == 0
				types[1]
			else
				types[0]
			end
		end

		def self.subsidiaryMap #:nodoc:
			nil
		end
	end

	# A utility class that handles a few details for the DomainObject class. All 
	# the methods here are usually called as methods of DomainObject, and then 
	# delegated to this class.
	class ObjectType
		@@instances = {}
		
		def self.flush #:nodoc:
			@@instances = {}
		end

		def self.getObjectType( aClass ) #:nodoc:
			instance = @@instances[aClass]
			if instance.nil?
				@@instances[aClass] = new( aClass )
				instance = @@instances[aClass]
			end
			instance
		end

		private_class_method :new

		def initialize(object_type) #:nodoc:
			@object_type = object_type
			( @class_fields, @xmlParser, @table_name ) = [ nil, nil, nil ]
		end

		# Returns an Array of ObjectField instances for this domain class, parsing
		# them from XML if necessary.
		def get_class_fields
			unless @class_fields
				try_load_xml_parser
				if @xmlParser
					@class_fields = @xmlParser.get_class_fields
				else
					error_msg = "Couldn't find either an XML class description file " +
											"or get_class_fields method for " + @object_type.name
					raise MissingError, error_msg, caller
				end
			end
			@class_fields
		end

		# Returns the name of the primary key in the database, retrieving it from
		# the class definition XML if necessary.
		def sql_primary_key_name( set_sql_primary_key_name = nil )
			if set_sql_primary_key_name
				@sql_primary_key_name = set_sql_primary_key_name
			elsif @sql_primary_key_name
				@sql_primary_key_name
			else
				try_load_xml_parser
				if !@xmlParser.nil? && ( spkn = @xmlParser.sql_primary_key_name )
					spkn
				else
					'pkId'
				end
			end
		end

		# Returns the table name, which is assumed to be the domain class name 
		# pluralized, and with the first letter lowercase. A User class is
		# assumed to be stored in a "users" table, while a ProductCategory class is
		# assumed to be stored in a "productCategories" table.
		def table_name( set_table_name = nil )
			if set_table_name
				@table_name = set_table_name
			elsif @table_name
				@table_name
			else
				try_load_xml_parser
				if (!@xmlParser.nil? && table_name = @xmlParser.table_name)
					table_name
				else
					table_name = @object_type.bareName
					table_name[0] = table_name[0..0].downcase
					English.plural table_name
				end
			end
		end
		
		def try_load_xml_parser
			require 'lafcadio/domain'
			dirName = LafcadioConfig.new['classDefinitionDir']
			xmlFileName = @object_type.bareName + '.xml'
			xmlPath = File.join( dirName, xmlFileName )
			xml = ''
			begin
				File.open( xmlPath ) { |file| xml = file.readlines.join }
				@xmlParser = ClassDefinitionXmlParser.new( @object_type, xml )
			rescue Errno::ENOENT
				# no xml file, so no @xmlParser
			end
		end
	end
end