require 'lafcadio'
require 'lafcadio/test'
require 'test/unit'

include Lafcadio

unless defined? DobjB
	class DobjB < DomainObject; end
end

class DobjA < DomainObject
	domain_object DobjB
	string        'text_field'

	mock_value :text_field, Proc.new { 'foobar' }
	
	def post_commit_trigger
		dobj_b.db_object if dobj_b.is_a? DomainObjectProxy
	end
end

class DobjB < DomainObject
	domain_object DobjA
end

class DobjC < DomainObject
	string 'some_text'

	default_mock_available false
end

class DobjD < DomainObject
	domain_object DobjA
	
	mock_value :dobj_a, nil
end

class DobjE < DomainObject
	string 'text_here'

	def pre_commit_trigger; raise if pk_id; end
end

class DobjF < DomainObject
	string        'overridden_in_child'
	string        'parent_text'
	domain_object DobjA
end

class DobjG < DobjF
	string 'child_text'
	
	mock_value :overridden_in_child, 'some other string'
end

class DobjH < DobjF
	string 'text_for_dobj_h'
	
	mock_value :overridden_in_child, 'string just for DobjH'
end

class TestDomainMock < Test::Unit::TestCase
	def setup
		@mock_object_store = MockObjectStore.new
		ObjectStore.set_object_store @mock_object_store
		LafcadioConfig.set_values( {} )
	end

	def test_commits_linked_dobjs
		dobj_a = DobjA.custom_mock
		@mock_object_store.dobj_b 1
	end
	
	def test_custom
		dobj_a = DobjA.custom_mock
		assert( dobj_a.pk_id > 1 )
		assert_equal( dobj_a, @mock_object_store.dobj_a( dobj_a.pk_id ) )
		dobj_a2 = DobjA.custom_mock
		assert( dobj_a2.pk_id > dobj_a.pk_id )
		assert_not_equal( dobj_a, dobj_a2 )
		assert_equal( dobj_a2, @mock_object_store.dobj_a( dobj_a2.pk_id ) )
		dobj_a3 = DobjA.new( 'text_field' => 'something' )
		dobj_a3.commit
		assert( dobj_a3.pk_id > dobj_a2.pk_id )
		dobj_a4 = DobjA.custom_mock
		assert( dobj_a4.pk_id > dobj_a3.pk_id )
	end
	
	def test_custom_linking_to_custom
		dobj_a = DobjA.custom_mock( 'pk_id' => 99, 'dobj_b' => nil )
		@mock_object_store.dobj_a( dobj_a.pk_id )
		dobj_b = DobjB.custom_mock( 'dobj_a' => dobj_a )
		@mock_object_store.dobj_a( dobj_a.pk_id )
		@mock_object_store.dobj_b( dobj_b.pk_id )
	end

	def test_cyclical_inclusion
		dobj_a = DobjA.default_mock
		assert_equal( dobj_a, dobj_a.dobj_b.dobj_a )
		dobj_b = DobjB.default_mock
		assert_equal( dobj_b, dobj_a.dobj_b )
	end
	
	def test_default_always_has_pk_id_1
		1.upto( 5 ) do |i| DobjA.new( { 'pk_id' => i + 1 } ).commit; end
		assert_equal( 1, DobjA.default_mock.pk_id )
		assert_equal( 1, DobjB.default_mock.dobj_a.pk_id )
		assert( DobjA.custom_mock.pk_id > 6 )
	end
	
	def test_default_for_link
		dobj_d = DobjD.default_mock
		assert_nil dobj_d.dobj_a
		assert_equal( 0, @mock_object_store.all( DobjA ).size )
	end
	
	def test_default_mock_available
		assert_raise( TypeError ) { DobjC.default_mock }
	end
	
	def test_inheritance
		dobj_f = DobjF.default_mock
		assert_equal( 'test text', dobj_f.overridden_in_child )
		dobj_g = DobjG.default_mock
		assert_equal( 'test text', dobj_g.parent_text )
		assert_equal( 'test text', dobj_g.child_text )
		assert_equal( 'some other string', dobj_g.overridden_in_child )
		assert_equal( 1, dobj_g.dobj_a.pk_id )
		dobj_g.dobj_a.db_object
		assert_equal(
			'string just for DobjH', DobjH.default_mock.overridden_in_child
		)
	end
	
	def test_let_mock_object_store_set_pk_id_for_custom
		DobjE.custom_mock
		DobjE.default_mock
	end
	
	def test_mock_value_proc
		dobj_a = DobjA.default_mock
		assert_equal( 'foobar', dobj_a.text_field )
	end
	
	def test_non_default_args
		dobj_a1 = DobjA.default_mock
		assert_equal( 1, dobj_a1.pk_id )
		dobj_a99 = DobjA.custom_mock( 'pk_id' => 99 )
		assert_equal( 99, dobj_a99.pk_id )
		assert_not_equal( dobj_a1, dobj_a99 )
	end
end