require 'rubygems'
require 'dbi'
require_gem 'log4r'
require 'lafcadio/objectStore'
require 'lafcadio/util/LafcadioConfig'

module Lafcadio
	class DbBridge #:nodoc:
		@@dbh = nil
		@@lastPkIdInserted = nil
		
		def self._load(aString)
			aString =~ /dbh:/
			dbString = $'
			begin
				dbh = Marshal.load(dbString)
			rescue TypeError
				dbh = nil
			end
			new dbh
		end
		
		def initialize
			@db_conn = DbConnection.getDbConnection
			ObjectSpace.define_finalizer( self, proc { |id|
				DbConnection.getDbConnection.disconnect
			} )
		end

		def _dump(aDepth)
			dbDump = @dbh.respond_to?( '_dump' ) ? @dbh._dump : @dbh.class.to_s
			"dbh:#{dbDump}"
		end
		
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
		
		def executeCommit( sql, binds ); @db_conn.do( sql, *binds ); end
		
		def executeSelect(sql)
			maybeLog sql
			begin
				@db_conn.select_all( sql )
			rescue DBI::DatabaseError => e
				raise $!.to_s + ": #{ e.errstr }"
			end	
		end
		
		def getCollectionByQuery(query)
			require 'lafcadio/objectStore/SqlValueConverter'
			objectType = query.objectType
			executeSelect( query.toSql ).collect { |row_hash|
				objectType.new( SqlValueConverter.new( objectType, row_hash ) )
			}
		end
		
		def group_query( query )
			executeSelect( query.toSql )[0].collect { |val|
				if query.field_name != 'pkId'
					a_field = query.objectType.getField( query.field_name )
					a_field.valueFromSQL( val )
				else
					val.to_i
				end
			}
		end

		def lastPkIdInserted; @@lastPkIdInserted; end
		
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
	end
end
