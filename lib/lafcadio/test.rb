require 'lafcadio/depend'
require 'lafcadio/mock'
require 'lafcadio/util'
require 'test/unit'

# A test case that sets up a number of mock services. In writing an application 
# that uses Lafcadio you may find it convenient to inherit from this class.
class LafcadioTestCase < Test::Unit::TestCase
	include Lafcadio

  def setup
  	context = ContextualService::Context.instance
  	context.flush
    @mockObjectStore = MockObjectStore.new
		ObjectStore.set_object_store @mockObjectStore
		LafcadioConfig.set_values(
			'classDefinitionDir' => '../test/testData', 'dbhost' => 'localhost',
			'dbname' => 'test', 'dbpassword' => 'password', 'dbuser' => 'test',
			'domainFiles' => %w( ../test/mock/domain ),
			'logdir' => '../test/testOutput/', 'logSql' => 'n'
		)
  end
	
	def default_test; end
end

module Lafcadio
	def BooleanField.mock_value; true; end
	
	def DateField.mock_value; Date.today; end

	def DateTimeField.mock_value; Time.now; end
	
	module DomainMock
		Version = '0.1.0'
		
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
	
		class DomainClassSymbolMapper < Hash
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
	
		def self.commit_mock( args, caller = nil )
			dobj = self.new( args )
			link_fields = all_fields.select { |field| field.is_a? DomainObjectField }
			link_fields.each do |field|
				val = dobj.send( field.name )
				maybe_call_default_mock( field, caller ) if ( val and val.pk_id == 1 )
			end
			dobj.commit
			dobj
		end
	
		def self.custom_mock( custom_args = nil )
			dobj_args = default_args
			object_store = ObjectStore.get_object_store
			dbb = object_store.get_db_bridge
			dbb.set_next_pk_id( self, 2 ) if dbb.next_pk_id( self ) == 1
			dobj_args['pk_id'] = nil
			dobj_args = dobj_args.merge( custom_args ) if custom_args.is_a?( Hash )
			commit_mock( dobj_args )
		end
		
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
		
		def self.default_mock( calling_class = nil )
			if @@default_mock_available[self]
				begin
					dobj = ObjectStore.get_object_store.get( self, 1 )
					dobj
				rescue DomainObjectNotFoundError
					dbb = ObjectStore.get_object_store.get_db_bridge
					dbb.set_next_pk_id( self, 1 ) if dbb.next_pk_id( self ) > 1
					commit_mock( default_args, calling_class )
				end
			else
				raise( TypeError, self.name + ".default_mock not allowed", caller )
			end
		end

		def self.default_mock_available( is_avail )
			@@default_mock_available[self] = is_avail
		end
		
		def self.maybe_call_default_mock( field, caller )
			linked_type = field.linked_type
			begin
				ObjectStore.get_object_store.get( linked_type, 1 )
			rescue DomainObjectNotFoundError
				unless linked_type == caller
					linked_type.send( 'default_mock', self )
				end
			end
		end

		def self.mock_value( field_sym, value )
			@@default_arg_directives[self][field_sym.id2name] = value
		end
		
		def self.mock_values( hash )
			hash.each do |field_sym, value| mock_value( field_sym, value ); end
		end
	end
	
	class DomainObjectField < ObjectField
		def default_mock_value; DomainObjectProxy.new( linked_type, 1 ); end
	end
	
	def EmailField.mock_value; 'john.doe@email.com'; end

	def FloatField.mock_value; 0.0; end

	def IntegerField.mock_value; 1; end

	class ObjectField
		attr_writer :mock_value
	
		def default_mock_value; self.class.mock_value; end
	end

	def PrimaryKeyField.mock_value; nil; end

	def StringField.mock_value; 'test text'; end
	
	def TextListField.mock_value; %w( a b c ); end
end
