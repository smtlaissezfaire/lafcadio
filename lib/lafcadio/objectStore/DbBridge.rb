require 'rubygems'

require 'dbi'
require_gem 'log4r'
require 'lafcadio/util/LafcadioConfig'

module Lafcadio
	# The DbBridge manages the MySQL connection for the ObjectStore.
	class DbBridge
		@@dbh = nil
		@@lastPkIdInserted = nil
		@@dbName = nil
		@@connectionClass = DBI
		
		def DbBridge.setDbName(dbName)
			@@dbName = dbName
		end
		
		def DbBridge._load(aString)
			aString =~ /dbh:/
			dbString = $'
			begin
				dbh = Marshal.load(dbString)
			rescue TypeError
				dbh = nil
			end
			new dbh
		end
		
		def DbBridge.flushConnection
			@@dbh = nil
		end
		
		def DbBridge.setConnectionClass( aClass )
			@@connectionClass = aClass
		end
		
		def DbBridge.disconnect
			@@dbh.disconnect if @@dbh
		end
		
		def initialize(dbh = nil)
			if dbh == nil
				if @@dbh == nil
					config = LafcadioConfig.new
					dbName = @@dbName || config['dbname']
					dbAndHost = "dbi:Mysql:#{ dbName }:#{ config['dbhost'] }"
					@@dbh = @@connectionClass.connect( dbAndHost, config['dbuser'],
																						 config['dbpassword'] )
				end
			else
				@@dbh = dbh
			end
			@dbh = @@dbh
			ObjectSpace.define_finalizer( self, proc { |id| DbBridge.disconnect } )
		end
		
		# Hook for logging: Useful for testing.
		def maybeLog(sql)
			config = LafcadioConfig.new
			if config['logSql'] == 'y'
				sqllog = Log4r::Logger['sql'] || Log4r::Logger.new( 'sql' )
				filename = File.join( config['logdir'], config['sqlLogFile'] || 'sql' )
				outputter = Log4r::FileOutputter.new( 'outputter',
																							{ :filename => filename } )
				sqllog.outputters = outputter
				sqllog.info sql
			end
		end
		
		# Sends an insert, update, or delete statement to the database. This is 
		# only called by Committer#execute, which handles a lot of Ruby-level 
		# details such as triggers.
		def commit(dbObject)
			require 'lafcadio/objectStore/DomainObjectSqlMaker'
			sqlMaker = DomainObjectSqlMaker.new(dbObject)
			sqlMaker.sqlStatements.each { |sql, binds| executeCommit( sql, binds ) }
			if sqlMaker.sqlStatements[0].first =~ /insert/
				sql = 'select last_insert_id()'
				result = executeSelect( sql )
				@@lastPkIdInserted = result[0]['last_insert_id()'].to_i
			end
		end
		
		def executeCommit( sql, binds )
			@dbh.do( sql, *binds )
		end
		
		# When passed a query, executes that query and returns a Collection.
		def getCollectionByQuery(query)
			require 'lafcadio/objectStore/SqlValueConverter'
			objectType = query.objectType
			coll = []
			objects = []
			result = executeSelect query.toSql
			result.each { |row_hash|
				converter = SqlValueConverter.new(objectType, row_hash)
				obj = objectType.new converter.execute
				objects << obj
			}
			coll = coll.concat objects
			coll
		end
		
		def executeSelect(sql)
			maybeLog sql
			begin
				@dbh.select_all( sql )
			rescue DBI::DatabaseError => e
				raise $!.to_s + ": #{ e.errstr }"
			end	
		end
		
		def _dump(aDepth)
			if @db.respond_to? '_dump'
				dbDump = @db._dump
			else
				dbDump = @db.class.to_s
			end
			"dbh:#{dbDump}"
		end
		
		def lastPkIdInserted
			@@lastPkIdInserted
		end
		
		def getMax(objectType)
			require 'lafcadio/query'
			sql = Query::Max.new(objectType).toSql
			result = executeSelect sql
			result[0]['max(pkId)'].to_i
		end
	end
end
