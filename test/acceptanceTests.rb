require 'dbi'
require 'lafcadio/domain'
require 'lafcadio/objectStore'
require 'lafcadio/util'
require 'runit/testcase'

include Lafcadio

class AcceptanceTestCase < RUNIT::TestCase
	def setup
		super
		@dbh = get_dbh
		domain_classes.each { |domain_class| domain_class.create_table( @dbh ) }
		@object_store = ObjectStore.getObjectStore
	end
	
	def teardown
		domain_classes.each { |domain_class| domain_class.drop_table( @dbh ) }
		Context.instance.setObjectStore( nil )
	end

	def domain_classes; [ TestRow, TestChildRow ]; end
	
	def get_dbh
		LafcadioConfig.setFilename 'lafcadio/test/testconfig.dat'
		config = LafcadioConfig.new
		dbName = config['dbname']
		dbAndHost = "dbi:Mysql:#{ dbName }:#{ config['dbhost'] }"
		DBI.connect( dbAndHost, config['dbuser'], config['dbpassword'] )
	end
end

class TestRow < DomainObject
	def self.create_table( dbh )
		dbh.do( 'drop table if exists testrows' )
		createSql = <<-CREATE
create table testrows (
	pkId int not null auto_increment,
	primary key (pkId),
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

	def TestRow.getClassFields
		fields = []
		fields << TextField.new( self, 'text_field' )
		fields << DateTimeField.new( self, 'date_time' )
		fields << BooleanField.new( self, 'bool_field' )
		fields << BlobField.new( self, 'blob_field' )
		text2 = TextField.new( self, 'text2' )
		text2.dbFieldName = 'text_field2'
		fields << text2
		fields
	end
	
	def TestRow.sqlPrimaryKeyName
		'pkId'
	end
end

class TestChildRow < TestRow
	def self.create_table( dbh )
		dbh.do( 'drop table if exists testchildrows' )
		createSql = <<-CREATE
create table testchildrows (
	pkId int not null auto_increment,
	primary key (pkId),
	child_text_field text
)
		CREATE
		dbh.do( createSql )
	end
	
	def self.drop_table( dbh ); dbh.do( 'drop table testchildrows' ); end

	def self.getClassFields
		fields = []
		fields << TextField.new( self, 'child_text_field' )
		fields
	end
	
	def self.sqlPrimaryKeyName
		'pkId'
	end
end

class AccTestBlobField < AcceptanceTestCase
	def test_delete
		test_str = 'The quick brown fox jumped over the lazy dog.'
		@dbh.do( 'insert into testrows( blob_field ) values( ? )', test_str )
		test_row = @object_store.getTestRow( 1 )
		test_row.delete = true
		test_row.commit
		assert_equal( 0, @object_store.getAll( TestRow ).size )
	end

	def test_insert
		test_str = 'The quick brown fox jumped over the lazy dog.'
		test_row = TestRow.new( 'blob_field' => test_str )
		test_row.commit
		@object_store.flush( test_row )
		test_row_prime = @object_store.getTestRow( 1 )
		assert_equal( test_str, test_row_prime.blob_field )
	end
	
	def test_nil_commit
		test_row = TestRow.new( {} )
		test_row.commit
		@object_store.flush( test_row )
		test_row_prime = @object_store.getTestRow( 1 )
		assert_nil( test_row_prime.blob_field )
	end
end

class AccTestBooleanField < AcceptanceTestCase
	def test_valueFromSQL
		@dbh.do( 'insert into testrows( bool_field ) values( 1 )' )
		test_row = @object_store.getTestRow( 1 )
		assert( test_row.bool_field )
		@dbh.do( 'insert into testrows( bool_field ) values( 0 )' )
		test_row2 = @object_store.getTestRow( 2 )
		assert( !test_row2.bool_field )
	end
end

class AccTestDateTimeField < AcceptanceTestCase
	def test_valueFromSQL
		@dbh.do( 'insert into testrows( date_time ) values( "2004-01-01" )' )
		test_row = @object_store.getTestRow( 1 )
		assert_equal( Time.gm( 2004, 1, 1 ), test_row.date_time )
		@dbh.do( 'insert into testrows( ) values( )' )
		test_row2 = @object_store.getTestRow( 2 )
		assert_nil( test_row2.date_time )
	end
end

class AccTestDomainObjInheritance < AcceptanceTestCase
	def test_insert
		child = TestChildRow.new( 'text_field' => 'text',
		                          'child_text_field' => 'child text' )
		child.commit
		all_dobjs = @object_store.getAll( TestChildRow )
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
		coll = @object_store.getTestRows { |test_row|
			test_row.text_field.equals( 'some text' )
		}
		assert_equal( 1, coll.size )
		test_row_prime = coll.first
		proxy = DomainObjectProxy.new( test_row_prime )
		assert_equal( proxy.hash, test_row_prime.hash )
	end
end

class AccTestEquals < AcceptanceTestCase
	def test_dbFieldName
		row = TestRow.new( 'text2' => 'some text' )
		row.commit
		cond = Query::Equals.new( 'text2', 'some text', TestRow )
		assert_equal( 1, @object_store.getSubset( cond ).size )
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
		testrow = @object_store.getTestRow( 1 )
		testrow.commit
		text2 = "Por favor, don't just forward the icon through email\n'cause then you won't be able to see 'em through the web interface."
		@dbh.do( 'insert into testrows( text_field ) values( ? )', text2 )
		testrow2 = @object_store.getTestRow( 2 )
		assert_equal( text2, testrow2.text_field )
		testrow2.commit
		text3 = "\n'''the defense asked if two days of work"
		test_row3 = TestRow.new( 'text_field' => text3 )
		test_row3.commit
		test_row3_prime = @object_store.getTestRow( 3 )
		assert_equal( text3, test_row3_prime.text_field )
	end
end