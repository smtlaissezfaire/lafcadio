require 'lafcadio/objectField/LinkField'
require 'lafcadio/objectStore/DomainComparable'
require 'lafcadio/objectStore/DomainObjectProxy'

module Lafcadio
	# All classes that correspond to a table in the database need to be children 
	# of DomainObject.
	#
	# By default, Lafcadio assumes that every domain object is indexed by the
	# field "pkId" in the database schema. If you're dealing with a table that 
	# uses a different field name, override DomainObject.sqlPrimaryKeyName.
	#
	# Other fields are defined by overriding DomainObject.classFields. Once those 
	# fields are defined, every instance of that domain class has standard
	# accessors for each field.
	#
	# When new domain objects are instantiated, they don't have any pkId value.
	# Lafcadio distinguishes between objects that already exist in the database 
	# and objects that have yet to be inserted by testing for a non-nil pkId. 
	# When a new object is committed, its pkId is automatically set.
	#
	# Lafcadio assumes that a domain class corresponds to a table whose name is 
	# the plural of the class name, and whose first letter is lowercase. A User 
	# class is assumed to be stored in a "users" table, while a ProductCategory 
	# class is assumed to be stored in a "productCategories" table. Override
	# DomainObject.tableName to override this behavior.
	#
	# Domain classes can inherit from other domain classes; they have all the 
	# fields of any concrete superclasses plus any new fields defined for 
	# themselves. Lafcadio assumes that each concrete class has a corresponding 
	# table, and each table has an pkId field that is used to match rows between 
	# different levels.
	class DomainObject
		@@subclassHash = {}
		@@classFields = {}

		COMMIT_ADD = 1
		COMMIT_EDIT = 2
		COMMIT_DELETE = 3

		include DomainComparable
		
		def DomainObject.classFields
			classFields = @@classFields[self]
			unless classFields
				@@classFields[self] = self.getClassFields
				classFields = @@classFields[self]
			end
			classFields
		end

		# Returns an array of subclasses that cannot be instantiated.
		def DomainObject.abstractSubclasses
			require 'lafcadio/domain'
			[ MapObject ]
		end

		# Returns an array consisting of this class, and any concrete classes it 
		# might inherit from.
		def DomainObject.selfAndConcreteSuperclasses
			classes = [ ]
			anObjectType = self
			until(anObjectType == DomainObject ||
					abstractSubclasses.index(anObjectType) != nil)
				classes << anObjectType
				anObjectType = anObjectType.superclass
			end
			classes
		end

		def DomainObject.method_missing(methodId)
			require 'lafcadio/domain'
			ObjectType.getObjectType( self ).send( methodId.id2name )
		end

		# Returns the ObjectField instance corresponding to fieldName.
		def DomainObject.getClassField(fieldName)
			field = nil
			self.classFields.each { |aField|
				field = aField if aField.name == fieldName
			}
			field
		end
		
		def DomainObject.getField( fieldName )
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

		# Returns a hash of every other domain class that has a LinkField that
		# points to this domain class; the hash keys are the classes and the hash 
		# values are the LinkFields from those classes that point to this domain 
		# class.
		def DomainObject.dependentClasses
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

		def DomainObject.objectType
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
		
		# By hooking into DomainObject.inherited (which is called by Ruby every 
		# time a subclass is defined), DomainObject maintains a hash of every 
		# defined subclass.
		def DomainObject.inherited(subclass)
			@@subclassHash[subclass] = true
		end
		
		# Returns an array of subclasses of DomainObject.
		def DomainObject.subclasses
			@@subclassHash.keys
		end

		# Returns true for all classes that are concrete domain object
		# classes, as opposed to DomainObject and others that are abstract
		# super classes. 
		def DomainObject.isConcrete?
		  (self != DomainObject && abstractSubclasses.index(self).nil?)
		end
		
		# Is this Domain object based on another, ie: are there two tables and 
		# not just one on the database layer ? 
		def DomainObject.isBasedOn?
		  self.superclass.isConcrete?
		end

		def self.getDomainDirs
			config = LafcadioConfig.new
			classPath = config['classpath']
			domainDirStr = config['domainDirs']
			if domainDirStr
				domainDirs = domainDirStr.split(',')
			else
				domainDirs = [ classPath + 'domain/' ]
			end
		end
		
		# Looks for the domain class whose name equals <tt>typeString</tt>.
		def self.getObjectTypeFromString(typeString)
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

		attr_accessor :delete, :errorMessages, :pkId, :lastCommit, :fields
		protected :fields

		# fieldHash should contain key-value associations for the different
		# fields of this domain class. For example, instantiating a User class 
		# might look like:
		#
		#   User.new ({ 'firstNames' => 'John', 'lastName' => 'Doe',
		#               'email' => 'john.doe@email.com', 'password' => 'l33t' })
		#
		# In normal usage any code you write that creates a domain object will not
		# define the 'pkId' field. The system assumes that a domain object with an
		# undefined pkId has yet to be inserted into the database, and when you
		# commit the domain object an pkId will automatically be assigned.
		#
		# If you're creating mock objects for unit tests, you can explicitly set 
		# the pkId to represent objects that already exist in the database.
		def initialize(fieldHash)
			@pkId = fieldHash["pkId"] != nil ? fieldHash["pkId"].to_i : nil
			@errorMessages = []
			@fields = {}
			self.class.allFields.each { |field|
				self.send("#{ field.name }=", fieldHash[field.name])
			}
		end
		
		def method_missing(methId, arg1 = nil)
			methodName = methId.id2name
			getter = false
			setter = false
			field = nil
			self.class.allFields.each { |aField|
				if aField.name == methodName
					getter = true
					field = aField
				elsif "#{ aField.name }=" == methodName
					setter = true
					field = aField
				end
			}
			if getter
				@fields[field.name]
			elsif setter
				if field.class <= LinkField
					if arg1.class != DomainObjectProxy && arg1
						arg1 = DomainObjectProxy.new(arg1)
					end
				end
				@fields[field.name] = arg1
			else
				super(methId)
			end
		end

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

		# In general, to_s is considered an invalid operation for domain objects, 
		# but this behavior can be overridden by subclasses.
		def to_s
			raise "Don't make me into a string unless the type asks"
		end
		
		def clone
			copy = super
			copy.fields = @fields.clone
			copy
		end
		
		# Commits this domain object to the database.
		def commit
			require 'lafcadio/objectStore/ObjectStore'
			ObjectStore.getObjectStore.commit self
		end
	end
end