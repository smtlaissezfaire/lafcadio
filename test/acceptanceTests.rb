require '../test/depend'
require 'dbi'
require 'lafcadio/domain'
require 'lafcadio/objectStore'
require 'lafcadio/util'
require 'test/unit'

include Lafcadio

class AcceptanceTestCase < Test::Unit::TestCase
	def setup
		super
		@dbh = get_dbh
		domain_classes.each { |domain_class| domain_class.create_table( @dbh ) }
		@object_store = ObjectStore.get_object_store
	end
	
	def teardown
		domain_classes.each { |domain_class| domain_class.drop_table( @dbh ) }
		ObjectStore.set_object_store( nil )
	end
	
	def default_test; end

	def domain_classes; [ TestBadRow, TestRow, TestChildRow, TestDiffPkRow ]; end
	
	def get_dbh
		LafcadioConfig.set_filename 'lafcadio/test/testconfig.dat'
		config = LafcadioConfig.new
		dbName = config['dbname']
		dbAndHost = "dbi:Mysql:#{ dbName }:#{ config['dbhost'] }"
		DBI.connect( dbAndHost, config['dbuser'], config['dbpassword'] )
	end
end

class TestBadRow < DomainObject
	def self.create_table( dbh )
		dbh.do( 'drop table if exists testbadrows' )
		createSql = <<-CREATE
create table testbadrows (
	objId int not null auto_increment,
	primary key (objId),
	text_field text
)
		CREATE
		dbh.do( createSql )
	end
	
	def self.drop_table( dbh ); dbh.do( 'drop table testbadrows' ); end

	def self.get_class_fields
		fields = super
		fields << TextField.new( self, 'text_field' )
		fields
	end
end

class TestDiffPkRow < DomainObject
	def self.create_table( dbh )
		dbh.do( 'drop table if exists testdiffpkrows' )
		createSql = <<-CREATE
create table testdiffpkrows (
	objId int not null auto_increment,
	primary key (objId),
	text_field text
)
		CREATE
		dbh.do( createSql )
	end
	
	def self.drop_table( dbh ); dbh.do( 'drop table testdiffpkrows' ); end

	def self.get_class_fields
		super.concat( [ TextField.new( self, 'text_field' ) ] )
	end
	
	sql_primary_key_name 'objId'
end

class TestRow < DomainObject
	def self.create_table( dbh )
		dbh.do( 'drop table if exists testrows' )
		createSql = <<-CREATE
create table testrows (
	pk_id int not null auto_increment,
	primary key (pk_id),
	text_field text,
	date_time datetime,
	bool_field tinyint,
	blob_field blob,
	text_field2 text
)
		CREATE
		dbh.do( createSql )
	end
	
	def self.drop_table( dbh ); dbh.do( 'drop table testrows' ); end

	def TestRow.get_class_fields
		fields = super
		fields << TextField.new( self, 'text_field' )
		fields << DateTimeField.new( self, 'date_time' )
		fields << BooleanField.new( self, 'bool_field' )
		fields << BlobField.new( self, 'blob_field' )
		text2 = TextField.new( self, 'text2' )
		text2.db_field_name = 'text_field2'
		fields << text2
		fields
	end
	
	def TestRow.sql_primary_key_name
		'pk_id'
	end
end

class TestChildRow < TestRow
	def self.create_table( dbh )
		dbh.do( 'drop table if exists testchildrows' )
		createSql = <<-CREATE
create table testchildrows (
	pk_id int not null auto_increment,
	primary key (pk_id),
	child_text_field text
)
		CREATE
		dbh.do( createSql )
	end
	
	def self.drop_table( dbh ); dbh.do( 'drop table testchildrows' ); end

	def self.get_class_fields
		fields = []
		fields << TextField.new( self, 'child_text_field' )
		fields
	end
	
	def self.sql_primary_key_name
		'pk_id'
	end
end

class AccTestBlobField < AcceptanceTestCase
	def test_delete
		test_str = 'The quick brown fox jumped over the lazy dog.'
		@dbh.do( 'insert into testrows( blob_field ) values( ? )', test_str )
		test_row = @object_store.get_test_row( 1 )
		test_row.delete = true
		test_row.commit
		assert_equal( 0, @object_store.get_all( TestRow ).size )
	end

	def test_insert
		test_str = 'The quick brown fox jumped over the lazy dog.'
		test_row = TestRow.new( 'blob_field' => test_str )
		test_row.commit
		@object_store.flush( test_row )
		test_row_prime = @object_store.get_test_row( 1 )
		assert_equal( test_str, test_row_prime.blob_field )
	end
	
	def test_nil_commit
		test_row = TestRow.new( {} )
		test_row.commit
		@object_store.flush( test_row )
		test_row_prime = @object_store.get_test_row( 1 )
		assert_nil( test_row_prime.blob_field )
	end
end

class AccTestBooleanField < AcceptanceTestCase
	def test_value_from_sql
		@dbh.do( 'insert into testrows( bool_field ) values( 1 )' )
		test_row = @object_store.get_test_row( 1 )
		assert( test_row.bool_field )
		@dbh.do( 'insert into testrows( bool_field ) values( 0 )' )
		test_row2 = @object_store.get_test_row( 2 )
		assert( !test_row2.bool_field )
	end
end

class AccTestDateTimeField < AcceptanceTestCase
	def test_value_from_sql
		@dbh.do( 'insert into testrows( date_time ) values( "2004-01-01" )' )
		test_row = @object_store.get_test_row( 1 )
		assert_equal( Time.gm( 2004, 1, 1 ), test_row.date_time )
		@dbh.do( 'insert into testrows( ) values( )' )
		test_row2 = @object_store.get_test_row( 2 )
		assert_nil( test_row2.date_time )
	end
end

class AccTestDomainObject < AcceptanceTestCase
	def test_sql_primary_key_name
		assert_equal( TestDiffPkRow.sql_primary_key_name,
		              TestDiffPkRow.get_class_fields.first.db_field_name )
	end
end

class AccTestDomainObjInheritance < AcceptanceTestCase
	def test_get
		child = TestChildRow.new( 'text_field' => 'text',
		                          'child_text_field' => 'child text' )
		child.commit
		child_prime = @object_store.get_test_child_row( 1 )
		assert_equal( child.text_field, child_prime.text_field )
	end

	def test_insert
		child = TestChildRow.new( 'text_field' => 'text',
		                          'child_text_field' => 'child text' )
		child.commit
		all_dobjs = @object_store.get_all( TestChildRow )
		assert_equal( 1, all_dobjs.size )
		child_prime = all_dobjs.first
		assert_equal( 'text', child_prime.text_field )
		assert_equal( 'child text', child_prime.child_text_field )
	end
end

class AccTestDomainObjectProxy < AcceptanceTestCase
	def test_correct_hashing
		test_row = TestRow.new( 'text_field' => 'some text' )
		test_row.commit
		coll = @object_store.get_test_rows { |test_row|
			test_row.text_field.equals( 'some text' )
		}
		assert_equal( 1, coll.size )
		test_row_prime = coll.first
		proxy = DomainObjectProxy.new( test_row_prime )
		assert_equal( proxy.hash, test_row_prime.hash )
	end
end

class AccTestEquals < AcceptanceTestCase
	def test_db_field_name
		row = TestRow.new( 'text2' => 'some text' )
		row.commit
		cond = Query::Equals.new( 'text2', 'some text', TestRow )
		assert_equal( 1, @object_store.get_subset( cond ).size )
		@object_store.flush( row )
		row_prime = @object_store.get_test_row( 1 )
		assert_equal( 'some text', row_prime.text2 )
	end
end

class AccTestObjectStore < AcceptanceTestCase
	def test_diff_pk
		mock = TestDiffPkRow.new( 'pk_id' => 1, 'text_field' => 'sample text' )
		mock_object_store = MockObjectStore.new
		mock_object_store.commit( mock )
		testdiffpkrow1_prime = mock_object_store.get_test_diff_pk_rows( 1,
		                                                            'pk_id' ).first
		assert_equal( 'sample text', testdiffpkrow1_prime.text_field )
		sql = <<-SQL
insert into testdiffpkrows( objId, text_field )
values( 1, 'sample text' )
		SQL
		@dbh.do( sql )
		assert_equal( 1, @object_store.get_max( TestDiffPkRow ) )
	end

	def test_large_result_set
		num_rows = 1000
		date_time_field = TestRow.get_field( 'date_time' )
		big_str = <<-BIG_STR
'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
		BIG_STR
		1.upto( num_rows ) { |i|
			text = "'row #{ i }'"
			date_time_str = date_time_field.value_for_sql( Time.now )
			bool_val = ( i % 2 == 0 ) ? "'1'" : "'0'"
			sql = <<-SQL
insert into testrows( text_field, date_time, bool_field, blob_field )
values( #{ text }, #{ date_time_str }, #{ bool_val }, #{ big_str } )
			SQL
			@dbh.do( sql )
		}
		rows = @object_store.get_test_rows
		assert_equal( num_rows, rows.size )
		1.upto( num_rows ) { |i|
			row = rows[i-1]
			assert_equal( i, row.pk_id )
			assert_equal( "row #{ i }", row.text_field )
		}
		result = @dbh.select_all( 'select * from testrows' )
		assert_equal( num_rows, result.size )
		result.each { |row_hash| value = row_hash['text_field'] }
	end

	def test_max
		y2k = Time.utc( 2000, 1, 1 )
		row1 = TestRow.new( 'date_time' => y2k )
		row1.commit
		row2 = TestRow.new( 'date_time' => Time.utc( 1999, 1, 1 ) )
		row2.commit
		assert_equal( y2k, @object_store.get_max( TestRow, 'date_time' ) )
	end
	
	def test_query_field_comparison
		row1 = TestRow.new( 'text_field' => 'a', 'text2' => 'b' )
		row1.commit
		row2 = TestRow.new( 'text_field' => 'c', 'text2' => 'c' )
		row2.commit
		matches = @object_store.get_test_rows { |test_row|
			test_row.text_field.equals( test_row.text2 )
		}
		assert_equal( 1, matches.size )
		assert_equal( 'c', matches.only.text_field )
		matches2 = @object_store.get_test_rows { |test_row|
			test_row.text2.equals( test_row.text_field )
		}
		assert_equal( 1, matches2.size )
		assert_equal( 'c', matches2.only.text_field )
	end
	
	def test_raise_if_bad_primary_key_map
		br1 = TestBadRow.new( 'text_field' => 'a' )
		br1.commit
		error_msg = 'The field "pk_id" can\'t be found in the table "testbadrows".'
		assert_raise( FieldMatchError, error_msg ) {
			@object_store.get_all( TestBadRow )
		}
	end
end

class AccTestTextField < AcceptanceTestCase
	def testEscaping
		text = <<-TEXT
// ~  $ \\
some other line
apostrophe's
		TEXT
		@dbh.do( 'insert into testrows( text_field ) values( ? )', text )
		testrow = @object_store.get_test_row( 1 )
		testrow.commit
		text2 = "Por favor, don't just forward the icon through email\n'cause then you won't be able to see 'em through the web interface."
		@dbh.do( 'insert into testrows( text_field ) values( ? )', text2 )
		testrow2 = @object_store.get_test_row( 2 )
		assert_equal( text2, testrow2.text_field )
		testrow2.commit
		text3 = "\n'''the defense asked if two days of work"
		test_row3 = TestRow.new( 'text_field' => text3 )
		test_row3.commit
		test_row3_prime = @object_store.get_test_row( 3 )
		assert_equal( text3, test_row3_prime.text_field )
	end
end
