require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/mock/MockFieldManager'

class CgiCommandTestCase < LafcadioTestCase
	def getCommand(fieldHash)
		self.class.commandType.new (MockFieldManager.new (fieldHash))
	end

	def execute(fieldHash)
		command = getCommand fieldHash
		command.execute
		command
	end

	def message(fieldHash)
		command = execute fieldHash
		command.message
	end
end
