dir = Dir.new 'test/'
dir.each { |entry|
	if ![ '.', '..', 'CVS' ].index(entry) && entry !~ /~$/
		begin
			subDirName = entry
			subDir = Dir.new "test/#{ subDirName }"
			subDir.each { |entry|
				if entry =~ /.rb$/
					require "test/#{subDirName}/#{entry}"
				end
			}
		rescue StandardError
			# not a directory, whatev
		end
	end
}
