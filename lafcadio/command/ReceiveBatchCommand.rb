require 'lafcadio/command/CgiCommand'

class ReceiveBatchCommand < CgiCommand
	def execute
		suffixStr = @fieldManager.get('suffix')
		if suffixStr.length == 2
			condition = Query::Like.new batchObjectType.sqlPrimaryKeyName, suffixStr,
					batchObjectType, Query::Like::PRE_ONLY
		elsif suffixStr == '0'
			condition = Query::Compare.new batchFieldName.sqlPrimaryKeyName, 10,
					batchObjectType, Query::Compare::LESS_THAN
		end
		dbObjects = @objectStore.getSubset condition
		dbObjects.each { |dbObject| performAction dbObject }
	end
end