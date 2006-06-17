require 'lafcadio/depend'
require 'lafcadio/mock'
require 'lafcadio/util'

module Lafcadio
	def BooleanField.mock_value #:nodoc:
		true
	end
	
	def DateField.mock_value #:nodoc:
		Date.today
	end

	def DateTimeField.mock_value #:nodoc:
		Time.now
	end
	
	# A convenience module for test-cases of Lafcadio-dependent applications.
	# Include this module in a test-case, and you automatically get the
	# class-level method <tt>setup_mock_dobjs</tt>. This calls
	# DomainObject.default_mock, and assigns the result to an instance variable 
	# named after the domain class. Note that if your test case also defines a 
	# <tt>setup</tt>, you should make sure to call <tt>super</tt> in that setup 
	# method to make <tt>setup_mock_dobjs</tt> work.
	#
	#   class User < Lafcadio::DomainObject
	#     strings :fname, :lname, :email
	#   end
	#
	#   class TestSendMessage < Test::Unit::TestCase
	#     include Lafcadio::DomainMock
	#     setup_mock_dobjs User
	#     def test_send_to_self
	#       SendMessage.new( 'sender' => @user, 'recipient' => @user )
	#       assert_equal( 1, Message.all.size )
	#     end
	#   end
	#
	# <tt>setup_mock_dobjs</tt> can handle plural domain classes:
	#
	#   setup_mock_dobjs User, Message
	#
	# It can also handle assignments to different instance variables:
	#
	#   setup_mock_dobjs User, '@sender'
	module DomainMock
		def self.included( includer )
			def includer.setup_mock_dobjs( *domain_classes_or_symbol_names )
				domain_classes = DomainClassSymbolMapper.new
				domain_classes_or_symbol_names.each { |domain_class_or_symbol_name|
					domain_classes.process( domain_class_or_symbol_name )
				}
				domain_classes.finish
				domain_classes.each { |my_domain_class, my_symbol_name|
					proc = Proc.new { |test_case|
						test_case.instance_variable_set(
							my_symbol_name, my_domain_class.default_mock
						)
					}
					setup_procs << proc
				}
			end

			def includer.setup_procs
				unless defined? @@all_setup_procs
					@@all_setup_procs = Hash.new { |hash, domain_class|
						hash[domain_class] = []
					}
				end
				@@all_setup_procs[self]
			end
		end
	
		def commit_domain_object( domain_class, non_default_values = {} )
			self.class.mock_domain_files.each do |file| require file; end
			dobj = domain_class.send( :custom_mock, non_default_values )
			dobj.commit
		end
	
		def method_missing( sym, *args )
			method_name = sym.id2name
			if method_name =~ /^custom_mock_(.*)/
				domain_class = Module.by_name( $1.underscore_to_camel_case )
				commit_domain_object( domain_class, *args )
			elsif method_name =~ /^default_mock_(.*)/
				Module.by_name( $1.underscore_to_camel_case ).default_mock
			else
				super
			end
		end
		
		def setup
			self.class.setup_procs.each { |proc| proc.call( self ) }
		end
	
		class DomainClassSymbolMapper < Hash #:nodoc:
			def initialize; @last_domain_class = nil; end
		
			def default_symbol_name( domain_class )
				"@#{ domain_class.name.camel_case_to_underscore }"
			end
			
			def finish
				if @last_domain_class
					self[@last_domain_class] = default_symbol_name( @last_domain_class )
				end
			end
		
			def process( domain_class_or_symbol_name )
				if domain_class_or_symbol_name.class == Class
					if @last_domain_class
						self[@last_domain_class] = default_symbol_name( @last_domain_class )
					end
					@last_domain_class = domain_class_or_symbol_name
				else
					self[@last_domain_class] = domain_class_or_symbol_name
					@last_domain_class = nil
				end
			end
		end
	end

	class DomainObject
		@@default_mock_available = Hash.new true
		@@default_arg_directives = Hash.new { |hash, a_class|
			default_args = {}
			a_class.all_fields.each do |field|
				default_args[field.name] = field.default_mock_value
			end
			hash[a_class] = default_args
		}
	
		def self.commit_mock( args, caller = nil ) #:nodoc:
			dobj = self.new( args )
			link_fields = all_fields.select { |field| field.is_a? DomainObjectField }
			link_fields.each do |field|
				val = dobj.send( field.name )
				maybe_call_default_mock( field, caller ) if ( val and val.pk_id == 1 )
			end
			dobj.commit
			dobj
		end
	
		# Commits and returns a custom mock object of the given domain class. All
		# the field values are set to defaults, except for the fields passed in
		# through +custom_args+. This mock object will have a +pk_id+ greater than
		# 1, and each successive call to DomainObject.custom_mock will return an
		# object with a unique +pk_id+.
		#
		# This class method is only visible if you include
		# <tt>lafcadio/test.rb</tt>.
		#
		#   class User < Lafcadio::DomainObject
		#     strings :fname, :lname, :email
		#   end
		#   u1 = User.custom_mock
		#   u1.fname # => 'test text'
		#   u1.lname # => 'test text'
		#   u1.email # => 'test text'
		#   u1.pk_id # => probably 2, guaranteed to be greater than 1
		#   u2 = User.custom_mock( 'fname' => 'Francis', 'lname' => 'Hwang' )
		#   u2.fname # => 'Francis'
		#   u2.lname # => 'Hwang'
		#   u2.email # => 'test text'
		#   u2.pk_id # => probably 3, guaranteed to not be u1.pk_id and to be
		#            #    greater than 1 
		def self.custom_mock( custom_args = nil )
			dobj_args = default_args
			object_store = ObjectStore.get_object_store
			dbb = object_store.db_bridge
			dbb.set_next_pk_id( self, 2 ) if dbb.next_pk_id( self ) == 1
			dobj_args['pk_id'] = nil
			if custom_args.is_a? Hash
				custom_args.each do |k, v| dobj_args[k.to_s] = v; end
			end
			commit_mock( dobj_args )
		end
		
		# Returns a hash of default arguments for mock instances of this domain
		# class. DomainObject.default_mock uses exactly these arguments to create
		# the default mock for a given domain class, and DomainObject.custom_mock
		# overrides some of the field arguments based on its custom arguments.
		#
		# By default this will retrieve simple values based on the field type:
		# * BooleanField:      +true+
		# * DateField:         Date.today
		# * DateTimeField:     Time.now
		# * DomainObjectField: The instance of the domain class with +pk_id+ 1
		# * EmailField:        "john.doe@email.com"
		# * FloatField:        0.0
		# * IntegerField:      1
		# * StringField:       "test text"
		# * TextListField:     [ 'a', 'b', 'c' ]
		#
		# You can override this method, if you like. However, it will probably be
		# simpler just to call DomainObject.mock_value.
		#
		# This class method is only visible if you include
		# <tt>lafcadio/test.rb</tt>.
		def self.default_args
			default_args = {}
			@@default_arg_directives[self].each do |name, value_or_proc|
				if value_or_proc.is_a? Proc
					default_args[name] = value_or_proc.call
				else
					default_args[name] = value_or_proc
				end
			end
			default_args
		end
		
		# Commits and returns a mock object of the given domain class. All
		# the field values are set to defaults. This mock object will have a
		# +pk_id+ of 1. Successive calls to DomainObject.default_mock will always 
		# return the same mock object.
		#
		# This class method is only visible if you include
		# <tt>lafcadio/test.rb</tt>.
		#
		#   class User < Lafcadio::DomainObject
		#     strings :fname, :lname, :email
		#   end
		#   u1 = User.default_mock
		#   u1.fname # => 'test text'
		#   u1.lname # => 'test text'
		#   u1.email # => 'test text'
		#   u1.pk_id # => 1
		def self.default_mock( calling_class = nil )
			if @@default_mock_available[self]
				begin
					dobj = ObjectStore.get_object_store.get( self, 1 )
					dobj
				rescue DomainObjectNotFoundError
					dbb = ObjectStore.get_object_store.db_bridge
					dbb.set_next_pk_id( self, 1 ) if dbb.next_pk_id( self ) > 1
					commit_mock( default_args, calling_class )
				end
			else
				raise( TypeError, self.name + ".default_mock not allowed", caller )
			end
		end

		def self.default_mock_available( is_avail ) #:nodoc:
			@@default_mock_available[self] = is_avail
		end
		
		def self.maybe_call_default_mock( field, caller ) #:nodoc:
			linked_type = field.linked_type
			begin
				ObjectStore.get_object_store.get( linked_type, 1 )
			rescue DomainObjectNotFoundError
				unless linked_type == caller
					linked_type.send( 'default_mock', self )
				end
			end
		end

		# Sets the mock value for the given field. These mock values are used in
		# DomainObject.default_mock and DomainObject.custom_mock
		#
		# This class method is only visible if you include
		# <tt>lafcadio/test.rb</tt>.
		#
		#   class User < Lafcadio::DomainObject
		#     strings :fname, :lname, :email
		#   end
		#   User.mock_value :fname, 'Bill'
		#   User.mock_value :lname, 'Smith'
		#   u1 = User.default_mock
		#   u1.fname # => 'Bill'
		#   u1.lname # => 'Smith'
		#   u1.email # => 'test text'
		#   u1.pk_id # => 1
		def self.mock_value( field_sym, value )
			@@default_arg_directives[self][field_sym.id2name] = value
		end
		
		# Sets the mock value for the fields in +hash+. These mock values are used
		# in DomainObject.default_mock and DomainObject.custom_mock
		#
		# This class method is only visible if you include
		# <tt>lafcadio/test.rb</tt>.
		#
		#   class User < Lafcadio::DomainObject
		#     strings :fname, :lname, :email
		#   end
		#   User.mock_values { :fname => 'Bill', :lname => 'Smith' }
		#   u1 = User.default_mock
		#   u1.fname # => 'Bill'
		#   u1.lname # => 'Smith'
		#   u1.email # => 'test text'
		#   u1.pk_id # => 1
		def self.mock_values( hash )
			hash.each do |field_sym, value| mock_value( field_sym, value ); end
		end
	end
	
	class DomainObjectField < ObjectField
		def default_mock_value #:nodoc:
			DomainObjectProxy.new( linked_type, 1 )
		end
	end
	
	def EmailField.mock_value #:nodoc:
		'john.doe@email.com'
	end

	def FloatField.mock_value #:nodoc:
		0.0
	end

	def IntegerField.mock_value #:nodoc:
		1
	end

	class ObjectField
		attr_writer :mock_value
	
		def default_mock_value #:nodoc:
			self.class.mock_value
		end
	end

	def PrimaryKeyField.mock_value #:nodoc:
		nil
	end

	def StringField.mock_value #:nodoc:
		'test text'
	end
	
	def TextListField.mock_value #:nodoc:
		%w( a b c )
	end
end
