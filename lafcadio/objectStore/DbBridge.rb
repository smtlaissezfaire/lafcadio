require "mysql"

# The DbBridge manages the MySQL connection for the ObjectStore.
class DbBridge
  @@db = nil
	@@lastObjIdInserted = nil
	@@dbName = nil

	def DbBridge.setDbName(dbName)
		@@dbName = dbName
	end

  def DbBridge._load(aString)
    aString =~ /db:/
    dbString = $'
    begin
      db = Marshal.load(dbString)
		rescue TypeError
			db = nil
		end
    new db
  end

  def DbBridge.flushConnection
    @@db = nil
  end

  def initialize(db = nil, mysqlClass = Mysql)
		require 'lafcadio/util/LafcadioConfig'
    if db == nil
      if @@db == nil
        config = LafcadioConfig.new
					@@db = mysqlClass.new config['dbhost'], config['dbuser'],
						config['dbpassword']
				dbName = @@dbName || config["dbname"]
        @@db.select_db(dbName)
      end
      @db = @@db
    else
      @db = db
    end
  end

	# Hook for logging: Useful for testing.
	def maybeLog(sql)
		require 'lafcadio/util/Logger'
#		Logger.log sql, 'sql'
	end

	# Sends a insert, update, or delete statement to the database. This is only 
	# called by Committer#execute, which handles a lot of Ruby-level details such 
	# as triggers.
  def commit(dbObject)
		require 'lafcadio/objectStore/DomainObjectSqlMaker'
    sqlMaker = DomainObjectSqlMaker.new(dbObject)
		sqlMaker.sqlStatements.each { |sql|
			executeQuery sql
		}
    if sqlMaker.sqlStatements[0] =~ /insert/
			sql = 'select last_insert_id()'
			result = executeQuery sql
      @@lastObjIdInserted = result.fetch_row[0].to_i
    end
  end

	# When passed a query, executes that query and returns a Collection.
	def getCollectionByQuery(query)
		require 'lafcadio/objectStore/Collection'
		require 'lafcadio/objectStore/SqlValueConverter'
		objectType = query.objectType
		coll = Collection.new objectType
    objects = []
		result = executeQuery query.toSql
    result.each_hash { |row_hash|
	    converter = SqlValueConverter.new(objectType, row_hash)
  	  obj = objectType.new converter.execute
			objects << obj
    }
		coll = coll.concat objects
		coll
	end

	def executeQuery(sql)
		maybeLog sql
		begin
			result = @db.query sql
		rescue MysqlError
			raise $!.to_s + ": #{sql}"
		end
		result		
	end

  def _dump(aDepth)
		if @db.respond_to? '_dump'
			dbDump = @db._dump
		else
			dbDump = @db.class.to_s
		end
    "db:#{dbDump}"
  end

	def lastObjIdInserted
		@@lastObjIdInserted
	end

	def getMax(objectType)
		require 'lafcadio/query/Max'
		sql = Query::Max.new(objectType).toSql
		result = executeQuery sql
		result.fetch_row[0].to_i
	end
end

