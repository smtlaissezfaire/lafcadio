require 'extensions/module'
require 'lafcadio/objectField'
require 'lafcadio/util'
require 'rexml/document'

module Lafcadio
	class ClassDefinitionXmlParser # :nodoc: all
		def initialize( domain_class, xml )
			@domain_class = domain_class
			@xmlDocRoot = REXML::Document.new( xml ).root
			@namesProcessed = {}
		end
		
		def get_class_field( fieldElt )
			className = fieldElt.attributes['class'].to_s
			name = fieldElt.attributes['name']
			if className != ''
				fieldClass = Class.by_name( 'Lafcadio::' + className )
				register_name( name )
				field = fieldClass.instantiate_from_xml( @domain_class, fieldElt )
				set_field_attributes( field, fieldElt )
			else
				msg = "Couldn't find field class '#{ className }' for field " +
				      "'#{ name }'"
				raise( MissingError, msg, caller )
			end
			field
		end

		def get_class_fields
			namesProcessed = {}
			pk_field = PrimaryKeyField.new( @domain_class )
			if ( spkn = @xmlDocRoot.attributes['sql_primary_key_name'] )
				pk_field.db_field_name = spkn
			end
			fields = [ pk_field ]
			@xmlDocRoot.elements.each('field') { |fieldElt|
				fields << get_class_field( fieldElt )
			}
			fields
		end
		
		def possible_field_attributes
			fieldAttr = []
			fieldAttr << FieldAttribute.new( 'size', FieldAttribute::INTEGER )
			fieldAttr << FieldAttribute.new( 'unique', FieldAttribute::BOOLEAN )
			fieldAttr << FieldAttribute.new( 'not_null', FieldAttribute::BOOLEAN )
			fieldAttr << FieldAttribute.new( 'enum_type', FieldAttribute::ENUM,
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

		def table_name
			@xmlDocRoot.attributes['table_name']
		end
		
		class FieldAttribute
			INTEGER = 1
			BOOLEAN = 2
			ENUM    = 3
			HASH    = 4
			
			attr_reader :name, :value_class
		
			def initialize( name, value_class, objectFieldClass = nil )
				@name = name; @value_class = value_class
				@objectFieldClass = objectFieldClass
			end
			
			def maybe_set_field_attr( field, fieldElt )
				setterMethod = "#{ name }="
				if field.respond_to?( setterMethod )
					if value_class != FieldAttribute::HASH
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
				elt.elements.each( @name.singular ) { |subElt|
					key = subElt.attributes['key'] == 'true'
					value = subElt.text.to_s
					hash[key] = value
				}
				hash
			end
			
			def value_from_string( valueStr )
				if @value_class == INTEGER
					valueStr.to_i
				elsif @value_class == BOOLEAN
					valueStr == 'y'
				elsif @value_class == ENUM
					eval "#{ @objectFieldClass.name }::#{ valueStr }"
				end
			end
		end

		class InvalidDataError < ArgumentError; end
	end

	module DomainComparable
		include Comparable

		# A DomainObject or DomainObjectProxy is compared by +domain_class+ and by
		# +pk_id+. 
		def <=>(anOther)
			if anOther.respond_to?( 'domain_class' )
				if self.domain_class == anOther.domain_class
					self.pk_id <=> anOther.pk_id
				else
					self.domain_class.name <=> anOther.domain_class.name
				end
			else
				nil
			end
		end
		
		def eql?(otherObj)
			self == otherObj
		end

		def hash; "#{ self.class.name } #{ pk_id }".hash; end
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
	#           <field name="lastName" class="StringField"/>
	#           <field name="email" class="StringField"/>
	#           <field name="password" class="StringField"/>
	#           <field name="birthday" class="DateField"/>
	#         </lafcadio_class_definition>
	# 2. Overriding DomainObject.get_class_fields. The method should return an Array
	#    of instances of ObjectField or its children. The order is unimportant.
	#    For example:
	#      class User < DomainObject 
	#        def User.get_class_fields 
	#          fields = [] 
	#          fields << StringField.new(self, 'firstName') 
	#          fields << StringField.new(self, 'lastName') 
	#          fields << StringField.new(self, 'email') 
	#          fields << StringField.new(self, 'password') 
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
	# to another row in the same table, you can use a DomainObjectField to express the
	# relation.
	#   <lafcadio_class_definition name="Message">
	#     <field name="subject" class="StringField" />
	#     <field name="body" class="StringField" />
	#     <field name="author" class="DomainObjectField" linked_type="User" />
	#     <field name="recipient" class="DomainObjectField" linked_type="User" />
	#     <field name="dateSent" class="DateField" />
	#   </lafcadio_class_definition>
 	#
 	#   msg = Message.new( 'subject' => 'hi there',
 	#                      'body' => 'You wanna go to the movies on Saturday?',
 	#                      'author' => john, 'recipient' => jane,
 	#                      'dateSent' => Date.today )
	#
	# = pk_id and committing
	# Lafcadio requires that each table has a numeric primary key. It assumes that
	# this key is named +pk_id+ in the database, though that can be overridden.
	#
	# When you create a domain object by calling new, you should not assign a
	# +pk_id+ to the new instance. The pk_id will automatically be set when you
	# commit the object by calling DomainObject#commit.
	#
	# However, you may want to manually set +pk_id+ when setting up a test case, so
	# you can ensure that a domain object has a given primary key.
	#
	# = Naming assumptions, and how to override them
	# By default, Lafcadio assumes that every domain object is indexed by the
	# field +pk_id+ in the database schema. If you're dealing with a table that 
	# uses a different field name, override DomainObject.sql_primary_key_name.
	# However, you will always use +pk_id+ in your Ruby code.
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
	# that each table has a +pk_id+ field that is used to match rows between
	# different levels.
	class DomainObject
		@@subclassHash = {}
		@@class_fields = {}
		@@pk_fields =
			Hash.new { |hash, key|
				pk_field = PrimaryKeyField.new( key )
				pk_field.db_field_name = @@sql_primary_keys[key]
				hash[key] = pk_field
			}
		@@sql_primary_keys = Hash.new( 'pk_id' )
		@@default_field_setup_hashes = Hash.new { |hash, key|
			hash[key] = Hash.new( {} )
		}

		COMMIT_ADD = 1
		COMMIT_EDIT = 2
		COMMIT_DELETE = 3

		include DomainComparable
		
		def self.[]( pk_id ); get( pk_id ); end
		
		def self.abstract_subclasses #:nodoc:
			require 'lafcadio/domain'
			[ MapObject ]
		end
		
		def self.all; ObjectStore.get_object_store.get_all( self ); end
		
		# Returns an array of all fields defined for this class and all concrete
		# superclasses.
		def self.all_fields
			all_fields = []
			self_and_concrete_superclasses.each { |aClass|
				aClass.class_fields.each { |field| all_fields << field }
			}
			all_fields
		end

		def self.class_fields #:nodoc:
			class_fields = @@class_fields[self]
			unless class_fields
				@@class_fields[self] = self.get_class_fields
				class_fields = @@class_fields[self]
				class_fields.each do |class_field|
					begin
						undef_method class_field.name.to_sym
					rescue NameError
						# not defined globally or in an included Module, skip it
					end
				end
			end
			class_fields
		end

		def self.create_field( field_class, *args )
			class_fields = @@class_fields[self]
			if args.last.is_a? Hash
				att_hash = args.last
			else
				att_hash = @@default_field_setup_hashes[self][field_class].clone
			end
			if class_fields.nil?
				class_fields = [ @@pk_fields[self] ]
				@@class_fields[self] = class_fields
			end
			if field_class == DomainObjectField
				att_hash['linked_type'] = args.first
				att_hash['name'] = args[1] if args[1] and !args[1].is_a? Hash
			else
				name = args.first
				att_hash['name'] = name == String ? name : name.to_s
			end
			field = field_class.instantiate_with_parameters( self, att_hash )
			unless class_fields.any? { |cf| cf.name == field.name }
				att_hash.each { |field_name, value|
					setter = field_name + '='
					field.send( setter, value ) if field.respond_to?( setter )
				}
				class_fields << field
			end
		end
		
		def self.default_field_setup_hash( field_class, hash )
			@@default_field_setup_hashes[self][field_class] = hash
		end

		def self.dependent_classes #:nodoc:
			dependent_classes = {}
			DomainObject.subclasses.each { |aClass|
				if aClass != DomainObjectProxy &&
						(!DomainObject.abstract_subclasses.index(aClass))
					aClass.class_fields.each { |field|
						if ( field.is_a?( DomainObjectField ) &&
						     field.linked_type == self.domain_class )
							dependent_classes[aClass] = field
						end
					}
				end
			}
			dependent_classes
		end
		
		def self.exist?( search_term, field_name = :pk_id )
			query = Query.infer( self ) { |dobj|
				dobj.send( field_name ).equals( search_term )
			}
			!ObjectStore.get_object_store.get_subset( query ).empty?
		end
		
		def self.first; all.first; end

		def self.get_class_field(fieldName) #:nodoc:
			field = nil
			self.class_fields.each { |aField|
				field = aField if aField.name == fieldName
			}
			field
		end
		
		def DomainObject.get_class_field_by_db_name( fieldName ) #:nodoc:
			self.class_fields.find { |field| field.db_field_name == fieldName }
		end

		# Returns an Array of ObjectField instances for this domain class, parsing
		# them from XML if necessary.
		def self.get_class_fields
			if self.methods( false ).include?( 'get_class_fields' )
				[ @@pk_fields[ self ] ]
			elsif abstract_subclasses.include?( self )
				[]
			else
				xmlParser = try_load_xml_parser
				if xmlParser
					xmlParser.get_class_fields
				else
					error_msg = "Couldn't find either an XML class description file " +
											"or get_class_fields method for " + self.name
					raise MissingError, error_msg, caller
				end
			end
		end

		def self.get_domain_dirs #:nodoc:
			if ( domainDirStr = LafcadioConfig.new['domainDirs'] )
				domainDirStr.split(',')
			else
				[]
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
				errStr = "Couldn't find field \"#{ fieldName }\" in " +
								 "#{ self } domain class"
				raise( MissingError, errStr, caller )
			end
		end

		def self.get_domain_class_from_string(typeString) #:nodoc:
			domain_class = nil
			require_domain_file( typeString )
			subclasses.each { |subclass|
				domain_class = subclass if subclass.to_s == typeString
			}
			if domain_class
				domain_class
			else
				raise CouldntMatchDomainClassError,
						"couldn't match domain_class #{typeString}", caller
			end
		end
		
		def self.get_link_field( linked_domain_class ) # :nodoc:
			class_fields.find { |field|
				field.is_a? DomainObjectField and field.linked_type == linked_domain_class
			}
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
		
		def self.last; all.last; end
		
		def self.method_missing( methodId, *args ) #:nodoc:
			method_name = methodId.id2name
			if method_name == 'get'
				if block_given?
					query = Query.infer( self ) { |dobj| yield( dobj ) }
					ObjectStore.get_object_store.get_subset( query )
				elsif args.size == 1
					ObjectStore.get_object_store.get( self, *args )
				else
					ObjectStore.get_object_store.get_filtered( self.name, *args )
				end
			else
				maybe_field_class_name = method_name.underscore_to_camel_case + 'Field'
				begin
					field_class = Lafcadio.const_get( maybe_field_class_name )
					create_field( field_class, *args )
				rescue NameError
					singular = method_name.singular
					if singular
						maybe_field_class_name = singular.underscore_to_camel_case + 'Field'
						begin
							field_class = Lafcadio.const_get( maybe_field_class_name )
							arg = args.shift
							until args.empty?
								next_arg = args.shift
								if next_arg.is_a? String or next_arg.is_a? Symbol
									create_field( field_class, arg )
									arg = next_arg
								else
									create_field( field_class, arg, next_arg )
									arg = args.shift
								end
							end
							create_field( field_class, arg ) unless arg.nil?
						rescue NameError
							super
						end
					else
						super
					end
				end
			end
		end
		
		def self.only; all.only; end

		def self.domain_class #:nodoc:
			self
		end

		def self.require_domain_file( typeString )
			typeString =~ /([^\:]*)$/
			fileName = $1
			get_domain_dirs.each { |domainDir|
				if Dir.entries(domainDir).index("#{fileName}.rb")
					require "#{ domainDir }#{ fileName }"
				end
			}
			if (domainFiles = LafcadioConfig.new['domainFiles'])
				domainFiles = domainFiles.split( ',' ) if domainFiles.is_a? String
				domainFiles.each { |domainFile| require domainFile }
			end
		end

		def self.self_and_concrete_superclasses # :nodoc:
			classes = [ ]
			a_domain_class = self
			until( a_domain_class == DomainObject ||
					   abstract_subclasses.index( a_domain_class ) != nil )
				classes << a_domain_class
				a_domain_class = a_domain_class.superclass
			end
			classes
		end

		def self.singleton_method_added( symbol )
			if symbol.id2name == 'sql_primary_key_name' && self < DomainObject
				begin
					get_field( 'pk_id' ).db_field_name = self.send( symbol )
				rescue NameError
					@@sql_primary_keys[self] = self.send( symbol )
				end
			end
		end
		
		# Returns the name of the primary key in the database, retrieving it from
		# the class definition XML if necessary.
		def self.sql_primary_key_name( set_sql_primary_key_name = nil )
			if set_sql_primary_key_name
				get_field( 'pk_id' ).db_field_name = set_sql_primary_key_name
			end
			get_field( 'pk_id' ).db_field_name
		end

		def self.subclasses #:nodoc:
			@@subclassHash.keys
		end

		# Returns the table name, which is assumed to be the domain class name 
		# pluralized, and with the first letter lowercase. A User class is
		# assumed to be stored in a "users" table, while a ProductCategory class is
		# assumed to be stored in a "productCategories" table.
		def self.table_name( set_table_name = nil )
			if set_table_name
				@table_name = set_table_name
			elsif @table_name
				@table_name
			else
				xmlParser = try_load_xml_parser
				if (!xmlParser.nil? && table_name = xmlParser.table_name)
					table_name
				else
					self.basename.camel_case_to_underscore.plural
				end
			end
		end

		def self.try_load_xml_parser
			require 'lafcadio/domain'
			dirName = LafcadioConfig.new['classDefinitionDir']
			xmlFileName = self.basename + '.xml'
			xmlPath = File.join( dirName, xmlFileName )
			xml = ''
			begin
				File.open( xmlPath ) { |file| xml = file.readlines.join }
				ClassDefinitionXmlParser.new( self, xml )
			rescue Errno::ENOENT
				# no xml file, so no @xmlParser
			end
		end
		
		attr_accessor :error_messages, :last_commit, :fields, :fields_set
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
		# define the +pk_id+ field. The system assumes that a domain object with an
		# undefined +pk_id+ has yet to be inserted into the database, and when you
		# commit the domain object a +pk_id+ will automatically be assigned.
		#
		# If you're creating mock objects for unit tests, you can explicitly set 
		# the +pk_id+ to represent objects that already exist in the database.
		def initialize(fieldHash)
			if fieldHash.respond_to? :keys
				fieldHash.keys.each { |key|
					begin
						self.class.get_field( key )
					rescue MissingError
						raise ArgumentError, "Invalid field name #{ key }"
					end
				}
			end
			@fieldHash = fieldHash
			@error_messages = []
			@fields = {}
			@fields_set = []
			@original_values = OriginalValuesHash.new( @fieldHash )
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
			if value && !pk_id
				raise "No point deleting an object that's not already in the DB"
			end
			@delete = value
		end
		
		def delete!
			self.delete = true
			commit
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
				new_symbol = ( 'get_' + methId.id2name ).to_sym
				object_store = ObjectStore.get_object_store
				if object_store.respond_to? new_symbol
					args = [ self ].concat args
					object_store.send( 'get_' + methId.id2name, *args )
				else
					super( methId, *args )
				end
			end
		end

		# Returns the subclass of DomainObject that this instance represents.
		# Because of the way that proxying works, clients should call this method
		# instead of Object.class.
		def domain_class
			self.class.domain_class
		end

		# This template method is called before every commit. Subclasses can 
		# override it to ensure code is executed before a commit.
		def pre_commit_trigger
			nil
		end

		# This template method is called after every commit. Subclasses can 
		# override it to ensure code is executed after a commit.
		def post_commit_trigger
			nil
		end

		def set_field( field, value ) #:nodoc:
			if field.class <= DomainObjectField
				if value.class != DomainObjectProxy && value
					value = DomainObjectProxy.new(value)
				end
			end
			if ( LafcadioConfig.new()['checkFields'] == 'onAllStates' &&
			     !field.instance_of?( PrimaryKeyField ) )
				field.verify( value, pk_id )
			end
			@fields[field.name] = value
			@fields_set << field
		end
		
		def update!( changes )
			changes.each do |sym, value| self.send( sym.to_s + '=', value ); end
			commit
		end
		
		def verify
			if ObjectStore.get_object_store.mock?
				self.class.get_class_fields.each { |field|
					field.verify( self.send( field.name ), self.pk_id )
				}
			end
		end
		
		class OriginalValuesHash < DelegateClass( Hash )
			def []=( key, val ); raise NoMethodError; end
		end
	end

	# Any domain class that is used mostly to map between two other domain 
	# classes should be a subclass of MapObject. Subclasses of MapObject should 
	# override MapObject.mappedTypes, returning a two-element array containing 
	# the domain classes that the map object maps between.
	class MapObject < DomainObject
		def self.other_mapped_type(firstType) #:nodoc:
			types = mappedTypes
			if types.index(firstType) == 0
				types[1]
			else
				types[0]
			end
		end

		def self.subsidiary_map #:nodoc:
			nil
		end
	end
end