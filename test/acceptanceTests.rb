require 'dbi'
require 'lafcadio/domain'
require 'lafcadio/objectStore'
require 'lafcadio/util'
require 'runit/testcase'

class AcceptanceTestCase < RUNIT::TestCase
end

class TestRow < DomainObject
	def TestRow.getClassFields
		fields = []
		fields << TextField.new( self, 'text_field' )
		fields
	end
	
	def TestRow.sqlPrimaryKeyName
		'pkId'
	end
end

class AccTestTextField < AcceptanceTestCase
	def testEscaping
		LafcadioConfig.setFilename 'lafcadio/testConfig.dat'
		config = LafcadioConfig.new
		dbName = config['dbname']
		dbAndHost = "dbi:Mysql:#{ dbName }:#{ config['dbhost'] }"
		dbh = DBI.connect( dbAndHost, config['dbuser'], config['dbpassword'] )
		dbh.do( 'drop table if exists testrows' )
		createSql = <<-CREATE
create table testrows (
	pkId int not null auto_increment,
	primary key (pkId),
	text_field text
)
		CREATE
		dbh.do( createSql )
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