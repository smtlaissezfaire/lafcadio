require 'dbi'
require 'lafcadio/domain'
require 'lafcadio/objectStore'
require 'lafcadio/util'
require 'runit/testcase'

class AcceptanceTestCase < RUNIT::TestCase
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
	date_time datetime
)
		CREATE
		dbh.do( createSql )
	end

	def TestRow.getClassFields
		fields = []
		fields << TextField.new( self, 'text_field' )
		fields << DateTimeField.new( self, 'date_time' )
		fields
	end
	
	def TestRow.sqlPrimaryKeyName
		'pkId'
	end
end

class AccTestDateTimeField < AcceptanceTestCase
	def test_valueFromSQL
		dbh = get_dbh
		TestRow.create_table( dbh )
		dbh.do( 'insert into testrows( date_time ) values( "2004-01-01" )' )
		test_row = ObjectStore.getObjectStore.getTestRow( 1 )
		assert_equal( Time.gm( 2004, 1, 1 ), test_row.date_time )
		dbh.do( 'insert into testrows( ) values( )' )
		test_row2 = ObjectStore.getObjectStore.getTestRow( 2 )
		assert_nil( test_row2.date_time )
	end
end

class AccTestTextField < AcceptanceTestCase
	def testEscaping
		dbh = get_dbh
		TestRow.create_table( dbh )
		text = <<-TEXT
// ~  $ \\
some other line
apostrophe's
		TEXT
		dbh.do( 'insert into testrows( text_field ) values( ? )', text )
		testrow = ObjectStore.getObjectStore.getTestRow( 1 )
		testrow.commit
	end
end