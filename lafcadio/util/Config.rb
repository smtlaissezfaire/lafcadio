class Config < Hash
	def Config.setFilename(filename)
		@@filename = filename
	end

  def initialize
   file = File.new @@filename
    file.each_line { |line|
			line =~ /^(.*?):(.*)$/
			self[$1] = $2
    }
  end
end
