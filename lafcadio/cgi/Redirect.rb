require 'lafcadio/util/LafcadioConfig'

class Redirect
	def initialize(localPath, solApDir = true)
		@localPath = localPath
		@soleApacheDirective = solApDir
	end

	def to_s
		config = LafcadioConfig.new
		str = "Location: #{config['url']}/#{@localPath}\n"
		str += "\n" if @soleApacheDirective
		str
	end
end