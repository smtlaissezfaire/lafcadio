require 'dbi'
require 'lafcadio/domain'
require 'lafcadio/objectStore'
require 'lafcadio/util'
require 'runit/testcase'

class AcceptanceTestCase < RUNIT::TestCase
	def setup
		super
		@dbh = get_dbh
		TestRow.create_table( @dbh )
		@object_store = ObjectStore.getObjectStore
	end
	
	def teardown
		TestRow.drop_table( @dbh )
		Context.instance.setObjectStore( nil )
	end

	def get_dbh
		LafcadioConfig.setFilename 'lafcadio/testConfig.dat'
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
	bool_field tinyint
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
		fields
	end
	
	def TestRow.sqlPrimaryKeyName
		'pkId'
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
	end
end