class FileManager
  def FileManager.copy(orig, new)
    `cp #{orig} #{new}`
  end

  def FileManager.exists(dir, filename)
    Dir.new(dir).entries.index(filename) != nil
  end

  def FileManager.delete(filename)
    `rm #{filename}`
  end

  def FileManager.move(orig, new)
    `mv #{orig} #{new}`
  end

  def FileManager.uniqueFilename(dir, firstGuess)
    filename = firstGuess
    while exists(dir, filename)
      filename = StrUtil.incrementFilename filename
    end
    filename
  end

	def FileManager.read(filename)
		contents = ""
		File.open(filename) { |file| contents = file.gets nil }
		contents
	end

	def FileManager.write(filename, contents)
		File.open(filename, File::CREAT | File::WRONLY) { |file|
			file.puts contents
		}
	end

	def FileManager.chmod(filename, perms)
		File.chmod(perms, filename)
	end

	def FileManager.ctime(filename)
		begin
			File.ctime(filename)
		rescue
			nil
		end
	end

	def FileManager.touch(fullPath)
		`touch #{fullPath}`
	end
end