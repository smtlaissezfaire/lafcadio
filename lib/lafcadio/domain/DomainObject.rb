require 'lafcadio/objectField/LinkField'
require 'lafcadio/objectStore/DomainComparable'
require 'lafcadio/objectStore/DomainObjectProxy'

module Lafcadio
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
	# 2. Overriding DomainObject.getClassFields. The method should return an Array
	#    of instances of ObjectField or its children. The order is unimportant.
	#    For example:
	#      class User < DomainObject 
	#        def User.getClassFields 
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
	# uses a different field name, override DomainObject.sqlPrimaryKeyName.
	# However, you will always use +pkId+ in your Ruby code.
	#
	# Lafcadio assumes that a domain class corresponds to a table whose name is 
	# the plural of the class name, and whose first letter is lowercase. A User 
	# class is assumed to be stored in a "users" table, while a ProductCategory 
	# class is assumed to be stored in a "productCategories" table. Override
	# DomainObject.tableName to override this behavior.
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
		@@classFields = {}

		COMMIT_ADD = 1
		COMMIT_EDIT = 2
		COMMIT_DELETE = 3

		include DomainComparable
		
		def DomainObject.classFields #:nodoc:
			classFields = @@classFields[self]
			unless classFields
				@@classFields[self] = self.getClassFields
				classFields = @@classFields[self]
			end
			classFields
		end

		def DomainObject.abstractSubclasses #:nodoc:
			require 'lafcadio/domain'
			[ MapObject ]
		end

		def DomainObject.selfAndConcreteSuperclasses # :nodoc:
			classes = [ ]
			anObjectType = self
			until(anObjectType == DomainObject ||
					abstractSubclasses.index(anObjectType) != nil)
				classes << anObjectType
				anObjectType = anObjectType.superclass
			end
			classes
		end

		def DomainObject.method_missing(methodId) #:nodoc:
			require 'lafcadio/domain'
			ObjectType.getObjectType( self ).send( methodId.id2name )
		end

		def DomainObject.getClassField(fieldName) #:nodoc:
			field = nil
			self.classFields.each { |aField|
				field = aField if aField.name == fieldName
			}
			field
		end
		
		def DomainObject.getField( fieldName ) #:nodoc:
			aDomainClass = self
			field = nil
			while aDomainClass < DomainObject && !field
				field = aDomainClass.getClassField( fieldName )
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

		def DomainObject.dependentClasses #:nodoc:
			dependentClasses = {}
			DomainObject.subclasses.each { |aClass|
				if aClass != DomainObjectProxy &&
						(!DomainObject.abstractSubclasses.index(aClass))
					aClass.classFields.each { |field|
						if field.class <= LinkField && field.linkedType == self.objectType
							dependentClasses[aClass] = field
						end
					}
				end
			}
			dependentClasses
		end

		def DomainObject.objectType #:nodoc:
			self
		end

		# Returns an array of all fields defined for this class and all concrete
		# superclasses.
		def DomainObject.allFields
			allFields = []
			selfAndConcreteSuperclasses.each { |aClass|
				aClass.classFields.each { |field| allFields << field }
			}
			allFields
		end
		
		def DomainObject.inherited(subclass) #:nodoc:
			@@subclassHash[subclass] = true
		end
		
		def DomainObject.subclasses #:nodoc:
			@@subclassHash.keys
		end

		def DomainObject.isConcrete? #:nodoc:
		  (self != DomainObject && abstractSubclasses.index(self).nil?)
		end
		
		def DomainObject.isBasedOn? #:nodoc:
		  self.superclass.isConcrete?
		end

		def self.getDomainDirs #:nodoc:
			config = LafcadioConfig.new
			classPath = config['classpath']
			domainDirStr = config['domainDirs']
			if domainDirStr
				domainDirs = domainDirStr.split(',')
			else
				domainDirs = [ classPath + 'domain/' ]
			end
		end
		
		def self.getObjectTypeFromString(typeString) #:nodoc:
			require 'lafcadio/objectStore/CouldntMatchObjectTypeError'
			objectType = nil
			typeString =~ /([^\:]*)$/
			fileName = $1
			getDomainDirs.each { |domainDir|
				if Dir.entries(domainDir).index("#{fileName}.rb")
					require "#{ domainDir }#{ fileName }"
				end
			}
			if (domainFilesStr = LafcadioConfig.new['domainFiles'])
				domainFilesStr.split(',').each { |domainFile|
					require domainFile
				}
			end
			subclasses.each { |subclass|
				objectType = subclass if subclass.to_s == typeString
			}
			if objectType
				objectType
			else
				raise CouldntMatchObjectTypeError,
						"couldn't match objectType #{typeString}", caller
			end
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

		def get_getter_field( methId ) #:nodoc:
			begin
				self.class.getField( methId.id2name )
			rescue MissingError
				nil
			end
		end

		def get_setter_field( methId ) #:nodoc:
			if methId.id2name =~ /(.*)=$/
				begin
					self.class.getField( $1 )
				rescue MissingError
					nil
				end
			else
				nil
			end
		end
		
		def get_field( field ) #:nodoc:
			unless @fields_set.include?( field )
				set_field( field, @fieldHash[field.name] )
			end
			@fields[field.name]
		end
		
		def set_field( field, value ) #:nodoc:
			if field.class <= LinkField
				if value.class != DomainObjectProxy && value
					value = DomainObjectProxy.new(value)
				end
			end
			@fields[field.name] = value
			@fields_set << field
		end

		# Returns the subclass of DomainObject that this instance represents.
		# Because of the way that proxying works, clients should call this method
		# instead of Object.class.
		def objectType
			self.class.objectType
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

		# Set the delete value to true if you want this domain object to be deleted
		# from the database during its next commit.
		def delete=(value)
			if value && !pkId
				raise "No point deleting an object that's not already in the DB"
			end
			@delete = value
		end

		# By default, to_s is considered an invalid operation for domain objects,
		# and will raise an error. This behavior can be overridden by subclasses.
		def to_s
			raise "Don't make me into a string unless the type asks"
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
			require 'lafcadio/objectStore/ObjectStore'
			ObjectStore.getObjectStore.commit self
		end
	end
end