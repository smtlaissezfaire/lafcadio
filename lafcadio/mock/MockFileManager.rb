class MockFileManager
	attr_reader :perms

  def initialize
    @files = {}
		@fileContents = {}
		@perms = {}
		@ctimes = {}
  end

  def addFile (dir, filename)
    filesForOneDir = @files[dir]
    if filesForOneDir == nil
      filesForOneDir = []
      @files[dir] = filesForOneDir
    end
    filesForOneDir << filename
		fullpath = dir && dir != "" ? dir + filename : filename
		@ctimes[fullpath] = Time.now
  end

  def exists (dir, filename)
    filesForOneDir = @files[dir]
    filesForOneDir != nil ? filesForOneDir.index(filename) != nil : false
  end

  def move (from, to)
		raise "source file missing" unless from
    copy (from, to)
    delete from
  end

  def copy (from, to)
		dir = getDir from
		filename = getFile from
    if exists (dir, filename)
			dir = getDir to
			filename = getFile to
      addFile dir, filename
    end
  end

  def delete (filename)
		dir = getDir filename
		filename = getFile filename
    filesForOneDir = @files[dir]
    filesForOneDir.delete(filename) if filesForOneDir != nil
  end

  def uniqueFilename (dir, firstGuess)
  	require 'lafcadio/util/StrUtil'
    filename = firstGuess
    while exists(dir, filename)
      filename = StrUtil.incrementFilename filename
    end
    filename
  end

	def save (path, contents)
		dir = getDir path
		filename = getFile path
		addFile dir, filename
		@fileContents[path] = contents
	end

	def read (filename)
		@fileContents[filename]
	end

	def write (filename, contents)
		save filename, contents
	end

	def chmod (filename, perms)
		@perms[filename] = perms
	end

	def getDir (fullPath)
		fullPath =~ /^(.*\/)(.*)$/
		$1
	end

	def getFile (fullPath)
		fullPath =~ /^(.*\/)(.*)$/
		$2
	end

	def touch (fullPath)
		dir = getDir fullPath
		file = getFile fullPath
		addFile (dir, file)
	end

	def ctime (fullPath)
		@ctimes [fullPath]
	end

	def setCTime (fullPath, ctime)
		@ctimes[fullPath] = ctime
	end
end