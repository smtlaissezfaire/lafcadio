require 'dbi'
require 'lafcadio/util/LafcadioConfig'

# The DbBridge manages the MySQL connection for the ObjectStore.
class DbBridge
	@@dbh = nil
	@@lastObjIdInserted = nil
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
	
	def initialize(dbh = nil)
		if dbh == nil
			if @@dbh == nil
				config = LafcadioConfig.new
				dbName = @@dbName || config['dbname']
				dbAndHost = "dbi:Mysql:#{ dbName }:#{ config['dbhost'] }"
				@@dbh = @@connectionClass.connect( dbAndHost, config['dbuser'],
				                                   config['dbpassword'] )
			end
			@dbh = @@dbh
		else
			@dbh = dbh
		end
	end
	
	# Hook for logging: Useful for testing.
	def maybeLog(sql)
		require 'lafcadio/util/Logger'
		config = LafcadioConfig.new
		Logger.log sql, 'sql' if config['logSql'] == 'y'
	end
	
	# Sends an insert, update, or delete statement to the database. This is only 
	# called by Committer#execute, which handles a lot of Ruby-level details such 
	# as triggers.
	def commit(dbObject)
		require 'lafcadio/objectStore/DomainObjectSqlMaker'
		sqlMaker = DomainObjectSqlMaker.new(dbObject)
		sqlMaker.sqlStatements.each { |sql| executeCommit( sql ) }
		if sqlMaker.sqlStatements[0] =~ /insert/
			sql = 'select last_insert_id()'
			result = executeSelect( sql )
			@@lastObjIdInserted = result[0]['last_insert_id()'].to_i
		end
	end
	
	def executeCommit( sql )
		@dbh.do( sql )
	end
	
	# When passed a query, executes that query and returns a Collection.
	def getCollectionByQuery(query)
		require 'lafcadio/objectStore/Collection'
		require 'lafcadio/objectStore/SqlValueConverter'
		objectType = query.objectType
		coll = Collection.new objectType
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
	
	def lastObjIdInserted
		@@lastObjIdInserted
	end
	
	def getMax(objectType)
		require 'lafcadio/query'
		sql = Query::Max.new(objectType).toSql
		result = executeSelect sql
		result[0]['max(objId)'].to_i
	end
end

