dir = Dir.new 'lafcadio/'
dir.each { |entry|
	if ![ '.', '..', 'CVS' ].index(entry) && entry !~ /~$/
		begin
			subDirName = entry
			subDir = Dir.new "lafcadio/#{ subDirName }"
			subDir.each { |entry|
				if entry =~ /.rb$/
					require "lafcadio/#{subDirName}/#{entry}"
				end
			}
		rescue StandardError
			# not a directory, whatev
		end
	end
}
