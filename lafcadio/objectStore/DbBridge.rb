require 'lafcadio/query/Max'
require 'lafcadio/query/Query'
require 'lafcadio/objectStore/DomainObjectSqlMaker'
require 'lafcadio/objectStore/SqlValueConverter'
require "mysql"

class DbBridge
  @@db = nil
	@@lastObjIdInserted = nil

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

  def initialize (db = nil, mysqlClass = Mysql)
		require 'lafcadio/util/Config'
    if db == nil
      if @@db == nil
        config = Config.new
					@@db = mysqlClass.new config['dbhost'], config['dbuser'],
						config['dbpassword']
        @@db.select_db(config["dbname"])
      end
      @db = @@db
    else
      @db = db
    end
  end

	def maybeLog (sql)
		require 'lafcadio/util/Logger'
#		Logger.log sql, 'sql'
	end

  def commit(dbObject)
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

	def getCollectionByQuery (query)
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

	def executeQuery (sql)
		maybeLog sql
		begin
			result = @db.query sql
		rescue MysqlError
			raise $!.to_s + ": #{sql}"
		end
		result		
	end

  def _dump (aDepth)
		if @db.respond_to? '_dump'
			dbDump = @db._dump
		else
			dbDump = @db.type.to_s
		end
    "db:#{dbDump}"
  end

	def lastObjIdInserted
		@@lastObjIdInserted
	end

	def getMax (objectType)
		sql = Query::Max.new(objectType).toSql
		result = executeQuery sql
		result.fetch_row[0].to_i
	end
end

