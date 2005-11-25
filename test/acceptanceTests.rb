require '../test/depend'
require 'dbi'
require 'lafcadio/domain'
require 'lafcadio/mock'
require 'lafcadio/objectStore'
require 'lafcadio/util'
require 'monitor'
require 'test/unit'

include Lafcadio

def connect_to_dbh
	LafcadioConfig.set_filename 'lafcadio/test/testconfig.dat'
	config = LafcadioConfig.new
	dbAndHost = "dbi:Mysql:#{ config['dbname'] }:#{ config['dbhost'] }"
	DBI.connect( dbAndHost, config['dbuser'], config['dbpassword'] )
end

class AcceptanceTestCase < Test::Unit::TestCase
	def self.domain_classes
		[ TestBadRow, TestChildRow, TestDiffPkRow, TestInnoDBRow, TestRow ]
	end
	
	def setup
		super
		@dbh = connect_to_dbh
		AcceptanceTestCase.domain_classes.each do |domain_class|
			domain_class.create_table @dbh
		end
		@object_store = ObjectStore.get_object_store
	end
	
	def teardown
		LafcadioConfig.set_values nil
		self.class.domain_classes.each do |domain_class|
			domain_class.drop_table @dbh
		end
		ObjectStore.set_object_store nil
	end
	
	def default_test; end
end

class DomainObject
	def self.create_table( dbh )
		drop_table dbh
		dbh.do create_sql
	end
	
	def self.drop_table( dbh )
		dbh.do "drop table if exists #{ self.table_name }"
	end
end

class TestBadRow < DomainObject
	def self.create_sql
		<<-CREATE
create table test_bad_rows (
	objId int not null auto_increment,
	primary key (objId),
	text_field text
)
		CREATE
	end

	string :text_field
end

class TestDiffPkRow < DomainObject
	def self.create_sql
		<<-CREATE
create table test_diff_pk_rows (
	objId int not null auto_increment,
	primary key (objId),
	text_field text
)
		CREATE
	end

	string :text_field
	sql_primary_key_name 'objId'
end

class TestInnoDBRow < DomainObject
	def self.create_sql
		<<-CREATE
create table test_inno_db_rows (
	pk_id int not null auto_increment,
	primary key (pk_id),
	string varchar(15)
) type=innodb
		CREATE
	end

	string 'string'
	table_name 'test_inno_db_rows'
end

class TestRow < DomainObject
	def self.create_sql
		<<-CREATE
create table test_rows (
	pk_id int not null auto_increment,
	primary key (pk_id),
	text_field text,
	date_time datetime,
	bool_field tinyint,
	blob_field blob,
	text_field2 text,
	test_diff_pk_row int
)
		CREATE
	end
	
	boolean       'bool_field'
	blob          'blob_field'
	date_time     'date_time'
	string        'text_field'
	string        'text2', { 'db_field_name' => 'text_field2' }
	domain_object TestDiffPkRow

	def TestRow.sql_primary_key_name
		'pk_id'
	end
end

class TestChildRow < TestRow
	def self.create_sql
		<<-CREATE
create table test_child_rows (
	pk_id int not null auto_increment,
	primary key (pk_id),
	child_text_field text
)
		CREATE
	end
	
	def self.get_class_fields
		fields = []
		fields << StringField.new( self, 'child_text_field' )
		fields
	end
	
	def self.sql_primary_key_name
		'pk_id'
	end
end

class AccTestBlobField < AcceptanceTestCase
	def test_delete
		test_str = 'The quick brown fox jumped over the lazy dog.'
		@dbh.do( 'insert into test_rows( blob_field ) values( ? )', test_str )
		test_row = @object_store.test_row 1
		test_row.delete = true
		test_row.commit
		assert_equal( 0, @object_store.all( TestRow ).size )
	end

	def test_insert
		test_str = 'The quick brown fox jumped over the lazy dog.'
		test_row = TestRow.new( 'blob_field' => test_str )
		test_row.commit
		@object_store.flush test_row
		test_row_prime = @object_store.test_row 1
		assert_equal( test_str, test_row_prime.blob_field )
	end
	
	def test_nil_commit
		test_row = TestRow.new( {} )
		test_row.commit
		@object_store.flush test_row
		test_row_prime = @object_store.test_row 1
		assert_nil test_row_prime.blob_field
	end
end

class AccTestBooleanField < AcceptanceTestCase
	def test_value_from_sql
		@dbh.do 'insert into test_rows( bool_field ) values( 1 )'
		test_row = @object_store.test_row 1
		assert test_row.bool_field
		@dbh.do 'insert into test_rows( bool_field ) values( 0 )'
		test_row2 = @object_store.test_row 2
		assert !test_row2.bool_field
	end
end

class AccTestContextualService < AcceptanceTestCase
	def test_get_garbage
		assert_raise( NoMethodError ) { ObjectStore.get_something_or_other }
	end
end

class AccTestDateTimeField < AcceptanceTestCase
	def test_value_from_sql
		@dbh.do 'insert into test_rows( date_time ) values( "2004-01-01" )'
		test_row = @object_store.test_row 1
		assert_equal( Time.gm( 2004, 1, 1 ), test_row.date_time )
		@dbh.do 'insert into test_rows( ) values( )'
		test_row2 = @object_store.test_row 2
		assert_nil test_row2.date_time
	end
end

class AccTestDomainObject < AcceptanceTestCase
	def test_dont_check_field_values_if_using_real_object_store
		LafcadioConfig.set_values(
			'checkFields' => 'onAllStates',
			'classDefinitionDir' => '../test/testData'
		)
		TestChildRow.new( {} )
	end

	def test_inheritance_get
		child = TestChildRow.new(
			'text_field' => 'text', 'child_text_field' => 'child text'
		).commit
		child_prime = @object_store.test_child_row 1
		assert_equal( child.text_field, child_prime.text_field )
	end

	def test_inheritance_insert
		TestChildRow.new(
			'text_field' => 'text', 'child_text_field' => 'child text'
		).commit
		all_dobjs = @object_store.all TestChildRow
		assert_equal( 1, all_dobjs.size )
		child_prime = all_dobjs.first
		assert_equal( 'text', child_prime.text_field )
		assert_equal( 'child text', child_prime.child_text_field )
	end

	def test_one_liners
		assert(
			TestRow.class_fields.any? { |field|
				field.is_a?( DomainObjectField ) && field.name == 'test_diff_pk_row'
			},
			TestRow.class_fields.inspect
		)
	end

	def test_sql_primary_key_name
		assert_equal(
			TestDiffPkRow.sql_primary_key_name,
			TestDiffPkRow.class_fields.first.db_field_name
		)
	end
end

class AccTestDomainObjectProxy < AcceptanceTestCase
	def test_correct_hashing
		TestRow.new( 'text_field' => 'some text' ).commit
		coll = @object_store.get_test_rows { |test_row|
			test_row.text_field.equals 'some text'
		}
		assert_equal( 1, coll.size )
		test_row_prime = coll.first
		proxy = DomainObjectProxy.new test_row_prime
		assert_equal( proxy.hash, test_row_prime.hash )
	end
end

class AccTestEquals < AcceptanceTestCase
	def test_db_field_name
		row = TestRow.new( 'text2' => 'some text' ).commit
		cond = Query::Equals.new( 'text2', 'some text', TestRow )
		assert_equal( 1, @object_store.query( cond ).size )
		@object_store.flush row
		row_prime = @object_store.test_row 1
		assert_equal( 'some text', row_prime.text2 )
	end
end

class AccTestObjectStore < AcceptanceTestCase
	include MonitorMixin
	
	def insert_1000_rows
		date_time_field = TestRow.field 'date_time'
		big_str = <<-BIG_STR
'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
		BIG_STR
		1.upto( 1000 ) { |i|
			text = "'row #{ i }'"
			date_time_str = date_time_field.value_for_sql( Time.now )
			bool_val = ( i % 2 == 0 ) ? "'1'" : "'0'"
			sql = <<-SQL
insert into test_rows( text_field, date_time, bool_field, blob_field )
values( #{ text }, #{ date_time_str }, #{ bool_val }, #{ big_str } )
			SQL
			@dbh.do sql
		}
	end

	def insert_rows_in_threads
		rows = {}
		threads = []
		10.times do
			threads << Thread.new {
				result = `ruby ../test/acceptanceTests.rb --commit_one_row`
				result =~ /(\d+):(.*)/
				synchronize {
					rows[$1] = $2
				}
			}
		end
		threads.each do |th| th.join; end
		rows
	end

	def test_atomic_pk_retrievals_after_insert
		rows = insert_rows_in_threads
		rows.keys.map { |key| key.to_i }.sort.each do |pk_id|
			text = rows[pk_id.to_s]
			assert_equal( text, TestRow[pk_id].text_field )
		end
	end
	
	def test_diff_pk
		sql = <<-SQL
insert into test_diff_pk_rows( objId, text_field )
values( 1, 'sample text' )
		SQL
		@dbh.do sql
		assert_equal( 1, @object_store.max( TestDiffPkRow ) )
	end
	
	def test_dumpable
		os_prime = Marshal.load( Marshal.dump( @object_store ) )
	end

	def test_get_by_domain_class
		diff_pk_row = TestDiffPkRow.new( 'text_field' => 'sample text' ).commit
		test_row = TestRow.new( 'test_diff_pk_row' => diff_pk_row ).commit
		assert_equal( 1, @object_store.get_test_rows( diff_pk_row ).size )
	end

	def test_large_result_set
		num_rows = 1000
		insert_1000_rows
		rows = @object_store.get_test_rows
		assert_equal( num_rows, rows.size )
		1.upto( num_rows ) { |i|
			row = rows[i-1]
			assert_equal( i, row.pk_id )
			assert_equal( "row #{ i }", row.text_field )
		}
		result = @dbh.select_all 'select * from test_rows'
		assert_equal( num_rows, result.size )
		result.each { |row_hash| value = row_hash['text_field'] }
	end

	def test_max
		assert_nil @object_store.max( TestRow )
		assert_nil @object_store.max( TestDiffPkRow )
		y2k = Time.utc( 2000, 1, 1 )
		row1 = TestRow.new( 'date_time' => y2k ).commit
		row2 = TestRow.new( 'date_time' => Time.utc( 1999, 1, 1 ) ).commit
		assert_equal( y2k, @object_store.max( TestRow, 'date_time' ).to_time )
	end
	
	def test_query_field_comparison
		TestRow.new( 'text_field' => 'a', 'text2' => 'b' ).commit
		TestRow.new( 'text_field' => 'c', 'text2' => 'c' ).commit
		matches = @object_store.get_test_rows { |test_row|
			test_row.text_field.equals test_row.text2
		}
		assert_equal( 1, matches.size )
		assert_equal( 'c', matches.only.text_field )
		matches2 = @object_store.get_test_rows { |test_row|
			test_row.text2.equals test_row.text_field
		}
		assert_equal( 1, matches2.size )
		assert_equal( 'c', matches2.only.text_field )
	end
	
	def test_raise_if_bad_primary_key_map
		TestBadRow.new( 'text_field' => 'a' ).commit
		error_msg = 'The field "pk_id" can\'t be found in the table "testbadrows".'
		assert_raise( FieldMatchError, error_msg ) {
			@object_store.all TestBadRow
		}
	end
	
	def test_transaction
		@object_store.transaction do |tr|
			TestInnoDBRow.new( 'string' => 'some string' ).commit
			tr.rollback
			raise 'should stop block before you get to this line'
		end
		assert_equal( 0, TestInnoDBRow.all.size )
		begin
			@object_store.transaction do |tr|
				TestInnoDBRow.new( 'string' => 'some string' ).commit
				raise Errno::ENOENT, 'msg here', caller
				raise 'should stop block before you get to this line'
			end
		rescue Errno::ENOENT
			assert_match( /msg here/, $!.to_s )
		end
		assert_equal( 0, TestInnoDBRow.all.size )
		@object_store.transaction do |tr|
			TestInnoDBRow.new( 'string' => 'some string' ).commit
		end
		assert_equal( 1, TestInnoDBRow.all.size )
		TestRow.new( 'text_field' => 'something' ).commit
		@object_store.transaction do |tr|
			tr.rollback
		end
	end
end

class AccTestQuery < AcceptanceTestCase
	def test_boolean_compound
		TestRow.new( 'text_field' => 'something', 'bool_field' => true ).commit
		TestRow.new( 'text_field' => 'something', 'bool_field' => false ).commit
		assert_equal(
			1, @object_store.get_test_rows { |tr|
				Query.And( tr.bool_field, tr.text_field.equals( 'something' ) )
			}.size
		)
	end
	
	def test_count
		TestRow.new( 'text2' => 'zzz' ).commit
		TestRow.new( 'text2' => 'yyy' ).commit
		TestRow.new( 'text2' => 'xxx' ).commit
		assert_equal( 3, TestRow.get( :group => :count ).only[:count] )
	end

	def test_order_by
		r1 = TestRow.new( 'text2' => 'zzz' ).commit
		r2 = TestRow.new( 'text2' => 'aaa' ).commit
		query = Query.new( TestRow )
		query.order_by = 'text2'
		assert_equal(
			'select * from test_rows order by text_field2 asc', query.to_sql
		)
		coll = @object_store.query query
		assert_equal( 2, coll.size )
		assert_equal( r2, coll.first )
	end
end

class AccTestStringField < AcceptanceTestCase
	def testEscaping
		text = <<-TEXT
// ~  $ \\
some other line
apostrophe's
		TEXT
		@dbh.do( 'insert into test_rows( text_field ) values( ? )', text )
		testrow = @object_store.test_row( 1 )
		testrow.commit
		text2 = "Por favor, don't just forward the icon through email\n'cause then you won't be able to see 'em through the web interface."
		@dbh.do( 'insert into test_rows( text_field ) values( ? )', text2 )
		testrow2 = @object_store.test_row( 2 )
		assert_equal( text2, testrow2.text_field )
		testrow2.commit
		text3 = "\n'''the defense asked if two days of work"
		test_row3 = TestRow.new( 'text_field' => text3 ).commit
		test_row3_prime = @object_store.test_row 3
		assert_equal( text3, test_row3_prime.text_field )
	end
end

if ARGV.include? '--commit_one_row'
	connect_to_dbh
	text = ''
	10.times do text << 'abcdefghijklmnopqrstuvwxyz'.split( // )[rand(25)]; end
	row = TestRow.new( 'text_field' => text ).commit
	puts "#{ row.pk_id }:#{ row.text_field }"
	exit
end

