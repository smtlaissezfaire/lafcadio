require '../test/depend'
require 'dbi'
require 'lafcadio/domain'
require 'lafcadio/mock'
require 'lafcadio/objectStore'
require 'lafcadio/util'
require 'monitor'
require 'test/unit'

include Lafcadio

class ObjectStore
	def self.flush_db_bridge; @@db_bridge = nil; end

	class DbConnection
		attr_accessor :allow_select
	
		def select_all( sql )
			if @allow_select.nil? or @allow_select
				@dbh.select_all sql
			else
				raise
			end
		end
	end
end

def connect_to_dbh( db_code )
	config = LafcadioConfig.new
	dbAndHost = [
		'dbi', db_code, config['dbname'], config['dbhost']
	].join( ':' )
	DBI.connect( dbAndHost, config['dbuser'], config['dbpassword'] )
end

def setup_lafcadio_config( db )
	LafcadioConfig.set_values(
		'dbuser' => 'test', 'dbpassword' => 'password', 'dbname' => 'test',
		'dbhost' => 'localhost', 'dbtype' => db
	)
end

class AcceptanceTestCase < Test::Unit::TestCase
	@@children_dbs = Hash.new { |h, k| h[k] = 'Mysql' }
	
	def self.db( db_code ); @@children_dbs[self] = db_code; end

	def self.domain_classes
		[ TestBadRow, TestChildRow, TestDiffPkRow, TestRow, TestTransactionRow ]
	end
	
	def setup
		super
		setup_lafcadio_config db
		@dbh = connect_to_dbh db
		AcceptanceTestCase.domain_classes.each do |domain_class|
			domain_class.create_table( @dbh, db )
		end
		@object_store = ObjectStore.get_object_store
	end
	
	def teardown
		ObjectStore.set_object_store nil
		ObjectStore.flush_db_bridge
		ObjectStore::DbConnection.get_db_connection.disconnect
		ObjectStore::DbConnection.set_db_connection nil
		self.class.domain_classes.each do |domain_class|
			domain_class.drop_table( @dbh, db )
		end
		@dbh.disconnect
		LafcadioConfig.set_values nil
	end
	
	def db; @@children_dbs[self.class]; end
	
	def default_test; end
end

class DomainObject
	def self.create_table( dbh, db )
		drop_table( dbh, db )
		dbh.do create_sql( db )
	end
	
	def self.create_sql( db )
		( db == 'Mysql' ) ? create_sql_mysql : create_sql_postgres
	end
	
	def self.drop_table( dbh, db )
		if db == 'Mysql'
			dbh.do "drop table if exists #{ self.table_name }"
		else
			sql =
					"select count(*) from pg_class where relname = '#{ self.table_name }'"
			matches = nil
			dbh.select_all( sql ) do |row| matches = row['count'].to_i; end
			dbh.do "drop table #{ self.table_name }" if matches > 0
		end
	end
end

class TestBadRow < DomainObject
	def self.create_sql_mysql
		<<-CREATE
create table test_bad_rows (
	objId int not null auto_increment,
	primary key (objId),
	text_field text
)
		CREATE
	end
	
	def self.create_sql_postgres
		<<-CREATE
create table test_bad_rows (
	objId serial primary key,
	text_field text
)
		CREATE
	end

	string :text_field
end

class TestDiffPkRow < DomainObject
	def self.create_sql_mysql
		<<-CREATE
create table test_diff_pk_rows (
	objId int not null auto_increment,
	primary key (objId),
	text_field text
)
		CREATE
	end
	
	def self.create_sql_postgres
		<<-CREATE
create table test_diff_pk_rows (
	objId serial primary key,
	text_field text
)
		CREATE
	end

	string :text_field
	sql_primary_key_name 'objId'
end

class TestTransactionRow < DomainObject
	def self.create_sql_mysql
		<<-CREATE
create table test_transaction_rows (
	pk_id int not null auto_increment,
	primary key (pk_id),
	string varchar(15)
) type=innodb
		CREATE
	end

	def self.create_sql_postgres
		<<-CREATE
create table test_transaction_rows (
	pk_id serial primary key,
	string varchar(15)
)
		CREATE
	end
	
	string 'string'
end

class TestRow < DomainObject
	def self.create_sql_mysql
		<<-CREATE
create table test_rows (
	pk_id int not null auto_increment,
	primary key (pk_id),
	text_field text,
	date_time datetime,
	bool_field tinyint,
	binary_field blob,
	text_field2 text,
	test_diff_pk_row int,
	test_transaction_row int
)
		CREATE
	end
	
	def self.create_sql_postgres
		<<-CREATE
create table test_rows (
	pk_id serial primary key,
	text_field text,
	date_time timestamp,
	bool_field boolean,
	binary_field bytea,
	text_field2 text,
	test_diff_pk_row int,
	test_transaction_row int
)
		CREATE
	end

	boolean       'bool_field'
	binary        'binary_field'
	date_time     'date_time'
	string        'text_field'
	string        'text2', { 'db_field_name' => 'text_field2' }
	domain_object TestDiffPkRow
	domain_object TestTransactionRow
	
	def TestRow.sql_primary_key_name
		'pk_id'
	end
end

class TestChildRow < TestRow
	def self.create_sql_mysql
		<<-CREATE
create table test_child_rows (
	pk_id int not null auto_increment,
	primary key (pk_id),
	child_text_field text
)
		CREATE
	end
	
	def self.create_sql_mysql
		<<-CREATE
create table test_child_rows (
	pk_id serial primary key,
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

module AccTestBinaryFieldMethods
	def test_delete
		test_str = 'The quick brown fox jumped over the lazy dog.'
		@dbh.do( 'insert into test_rows( binary_field ) values( ? )', test_str )
		test_row = @object_store.test_row 1
		test_row.delete = true
		test_row.commit
		assert_equal( 0, @object_store.all( TestRow ).size )
	end

	def test_insert
		test_str = 'The quick brown fox jumped over the lazy dog.'
		test_row = TestRow.new( 'binary_field' => test_str )
		test_row.commit
		@object_store.flush test_row
		test_row_prime = @object_store.test_row 1
		assert_equal( test_str, test_row_prime.binary_field )
	end
	
	def test_nil_commit
		test_row = TestRow.new( {} )
		test_row.commit
		@object_store.flush test_row
		test_row_prime = @object_store.test_row 1
		assert_nil test_row_prime.binary_field
	end
end

class AccTestBinaryFieldMysql < AcceptanceTestCase
	include AccTestBinaryFieldMethods
end

class AccTestBinaryFieldPostgres < AcceptanceTestCase
	db 'Pg'
	include AccTestBinaryFieldMethods
end

module AccTestBooleanFieldMethods
	def test_value_from_sql
		@dbh.do "insert into test_rows( bool_field ) values( #{ true_str } )"
		test_row = @object_store.test_row 1
		assert test_row.bool_field
		@dbh.do "insert into test_rows( bool_field ) values( #{ false_str } )"
		test_row2 = @object_store.test_row 2
		assert !test_row2.bool_field
	end
end

class AccTestBooleanFieldMysql < AcceptanceTestCase
	include AccTestBooleanFieldMethods
	
	def false_str; '0'; end
	
	def true_str; '1'; end
end

class AccTestBooleanFieldPostgres < AcceptanceTestCase
	db 'Pg'
	include AccTestBooleanFieldMethods

	def false_str; 'false'; end
	
	def true_str; 'true'; end
end

class AccTestContextualService < AcceptanceTestCase
	def test_get_garbage
		assert_raise( NoMethodError ) { ObjectStore.get_something_or_other }
	end
end

module AccTestDateTimeFieldMethods
	def test_value_from_sql
		@dbh.do "insert into test_rows( date_time ) values( #{ date_str } )"
		test_row = @object_store.test_row 1
		assert_equal( Time.gm( 2004, 1, 1 ), test_row.date_time )
		@dbh.do empty_insert_sql
		test_row2 = @object_store.test_row 2
		assert_nil test_row2.date_time
	end
end

class AccTestDateTimeFieldMysql < AcceptanceTestCase
	include AccTestDateTimeFieldMethods
	
	def date_str; '"2004-01-01"'; end
	
	def empty_insert_sql; 'insert into test_rows( ) values( )'; end
end

class AccTestDateTimeFieldPostgres < AcceptanceTestCase
	db 'Pg'
	include AccTestDateTimeFieldMethods
	
	def date_str; "'2004-01-01'"; end

	def empty_insert_sql; 'insert into test_rows default values'; end
end

class DomainObject
	# used in test_refresh_original_values_after_commit
	attr_accessor :original_values
end

module AccTestDomainObjectMethods
	def test_dont_check_field_values_if_using_real_object_store
		LafcadioConfig.set_values(
			'checkFields' => 'onAllStates',
			'classDefinitionDir' => '../test/testData'
		)
		TestChildRow.new( {} )
	end
end

class AccTestDomainObjectMysql < AcceptanceTestCase
	include AccTestDomainObjectMethods

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

	def test_refresh_original_values_after_commit
		tr = TestRow.new( 'text_field' => 'text' ).commit
		assert_equal( 'text', tr.original_values['text_field'] )
		tr.text_field = 'something else'
		assert_equal( 'text', tr.original_values['text_field'] )
		tr.commit
		assert_equal( 'something else', tr.original_values['text_field'] )
	end

	def test_sql_primary_key_name
		assert_equal(
			TestDiffPkRow.sql_primary_key_name,
			TestDiffPkRow.class_fields.first.db_field_name
		)
	end
end

class AccTestDomainObjectPostgres < AcceptanceTestCase
	db 'Pg'
	include AccTestDomainObjectMethods
end

class AccTestDomainObjectProxy < AcceptanceTestCase
	def test_correct_hashing
		TestRow.new( 'text_field' => 'some text' ).commit
		coll = @object_store.test_rows { |test_row|
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
insert into test_rows( text_field, date_time, bool_field, binary_field )
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
	
	def test_caching_accounts_for_limits_and_sort_by
		TestRow.new( 'text_field' => 'aza' ).commit
		TestRow.new( 'text_field' => 'bzb' ).commit
		TestRow.new( 'text_field' => 'czc' ).commit
		q = Query.infer( TestRow ) { |tr| tr.text_field.like( /z/ ) }
		assert_equal(
			3, @object_store.test_rows { |tr| tr.text_field.like( /z/ ) }.size
		)
		q = Query.infer( TestRow ) { |tr| tr.text_field.like( /z/ ) }
		q.limit = 0..0
		assert_equal( 1, @object_store.query( q ).size )
		q.limit = nil
		q.order_by = 'text_field'
		q.order_by_order = :desc
		assert_equal( 'aza', @object_store.query( q ).last.text_field )
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
	
	def test_eager_loading
		dpr = TestDiffPkRow.new( 'text_field' => 'text 1' ).commit
		idr = TestTransactionRow.new( 'string' => 'text 2' ).commit
		tr = TestRow.new(
			'text_field' => 'text 3', 'test_diff_pk_row' => dpr,
			'test_transaction_row' => idr
		).commit
		trs = TestRow.all( :include => :test_diff_pk_row )
		dbc = ObjectStore::DbConnection.get_db_connection
		dbc.allow_select = false
		assert_equal( 'text 1', trs.first.test_diff_pk_row.text_field )
		dbc.allow_select = true
		trs = TestRow.all(
			:include => [ :test_diff_pk_row, :test_transaction_row ]
		)
		dbc.allow_select = false
		assert_equal( 'text 1', trs.first.test_diff_pk_row.text_field )
		assert_equal( 'text 2', trs.first.test_transaction_row.string )
		dbc.allow_select = true
		tr2 = TestRow.new( 'text_field' => 'text 4' ).commit
		trs = TestRow.all( :include => :test_diff_pk_row )
		assert_equal( 2, trs.size )
	end

	def test_get_by_domain_class
		diff_pk_row = TestDiffPkRow.new( 'text_field' => 'sample text' ).commit
		test_row = TestRow.new( 'test_diff_pk_row' => diff_pk_row ).commit
		assert_equal( 1, @object_store.test_rows( diff_pk_row ).size )
	end

	def test_large_result_set
		num_rows = 1000
		insert_1000_rows
		rows = @object_store.test_rows
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
		matches = @object_store.test_rows { |test_row|
			test_row.text_field.equals test_row.text2
		}
		assert_equal( 1, matches.size )
		assert_equal( 'c', matches.only.text_field )
		matches2 = @object_store.test_rows { |test_row|
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
	
	def test_threading
		threads = []
		rows = []
		25.times do
			threads << Thread.new do
				row = TestRow.new( 'text_field' => rand( 10000 ).to_s ).commit
				synchronize do
					rows << row
				end
			end
		end
		threads.each do |th| th.join; end
		rows.each do |row|
			row_prime = TestRow[row.pk_id]
			assert_equal( row.pk_id, row_prime.pk_id )
			assert_equal(
				row.text_field, row_prime.text_field, "mismatch for row #{ row.pk_id }"
			)
		end
		rows.each do |row| @object_store.flush( row ); end
		rows.each do |row|
			row_prime = TestRow[row.pk_id]
			assert_equal( row.pk_id, row_prime.pk_id )
			assert_equal(
				row.text_field, row_prime.text_field, "mismatch for row #{ row.pk_id }"
			)
		end
	end
	
	def test_transaction
		@object_store.transaction do |tr|
			TestTransactionRow.new( 'string' => 'some string' ).commit
			tr.rollback
			raise 'should stop block before you get to this line'
		end
		assert_equal( 0, TestTransactionRow.all.size )
		begin
			@object_store.transaction do |tr|
				TestTransactionRow.new( 'string' => 'some string' ).commit
				raise Errno::ENOENT, 'msg here', caller
				raise 'should stop block before you get to this line'
			end
		rescue Errno::ENOENT
			assert_match( /msg here/, $!.to_s )
		end
		assert_equal( 0, TestTransactionRow.all.size )
		@object_store.transaction do |tr|
			TestTransactionRow.new( 'string' => 'some string' ).commit
		end
		assert_equal( 1, TestTransactionRow.all.size )
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
			1, @object_store.test_rows { |tr|
				Query.And( tr.bool_field, tr.text_field.equals( 'something' ) )
			}.size
		)
		TestRow.new( 'text_field' => 's', 'bool_field' => true ).commit
		qry = Query.infer( TestRow ) { |tr| tr.bool_field }
		qry.limit = 0..0
		qry = qry.and { |tr| tr.text_field.like( /^s/ ) }
		assert_equal( 1, @object_store.query( qry ).size )
	end
	
	def test_count
		TestRow.new( 'text2' => 'zzz' ).commit
		TestRow.new( 'text2' => 'yyy' ).commit
		TestRow.new( 'text2' => 'xxx' ).commit
		assert_equal( 3, TestRow.get( :group => :count ).only[:count] )
	end

	def test_order_by
		r1 = TestRow.new( 'text2' => 'zzz', 'text_field' => 'something' ).commit
		r2 = TestRow.new( 'text2' => 'aaa', 'text_field' => 'something' ).commit
		query = Query.new( TestRow )
		query.order_by = 'text2'
		assert_equal(
			'select * from test_rows order by text_field2 asc', query.to_sql
		)
		coll = @object_store.query query
		assert_equal( 2, coll.size )
		assert_equal( r2, coll.first )
		query2 = Query.infer( TestRow, :order_by => [ :text2 ] ) { |tr|
			tr.text_field.equals( 'something' )
		}
		assert_equal(
			"select * from test_rows where test_rows.text_field = 'something' " +
					"order by text_field2 asc",
			query2.to_sql
		)
		coll2 = @object_store.query query2
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
	setup_lafcadio_config 'Mysql'
	connect_to_dbh 'Mysql'
	text = ''
	10.times do text << 'abcdefghijklmnopqrstuvwxyz'.split( // )[rand(25)]; end
	row = TestRow.new( 'text_field' => text ).commit
	puts "#{ row.pk_id }:#{ row.text_field }"
	exit
end

