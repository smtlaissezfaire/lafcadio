require '../test/depend'

test_base = '../test/'
dir = Dir.new test_base
dir.each { |entry|
	if ![ '.', '..', 'CVS' ].index(entry) && entry !~ /~$/
		begin
			subDirName = entry
			subDir = Dir.new( File.join( test_base, subDirName ) )
			subDir.each { |entry|
				if entry =~ /.rb$/
					require File.join( test_base, subDirName, entry )
				end
			}
		rescue Errno::ENOTDIR
			# not a directory, whatev
		end
	end
}
