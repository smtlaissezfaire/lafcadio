[ 'lafcadio', 'test' ].each { |subDir|
	dir = Dir.new subDir
	dir.each { |entry|
		require "#{ subDir }/#{ entry }" if entry =~ /.rb$/
	}
}
