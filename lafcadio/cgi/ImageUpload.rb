class ImageUpload
  @@imgDir = "../img/"

  attr_accessor :desiredFilename, :contentType, :tempPath, :read

  def initialize (tempfile, fileManager = FileManager)
    @fileManager = fileManager
    if tempfile.respond_to? "content_type"
      @contentType = tempfile.content_type
    end
    if tempfile.respond_to? "original_filename"
      setDesiredFilename tempfile.original_filename
    end
    if tempfile.respond_to? "local_path"
      @tempPath = copyTempPath tempfile.local_path
    end
    if tempfile.respond_to? "read"
      @read = tempfile.read
    end
  end

  def setDesiredFilename (originalFilename)
    @desiredFilename = originalFilename.gsub (/ /, "_")
    if @contentType == "image/jpeg" && (@desiredFilename =~ /.jpg$/) == nil
      @desiredFilename += ".jpg"
    elsif @contentType == "image/gif" &&
      (@desiredFilename =~ /.gif$/) == nil
      @desiredFilename += ".gif"
    end
	  @desiredFilename = @fileManager.uniqueFilename(@@imgDir, @desiredFilename)
		@fileManager.touch @@imgDir + @desiredFilename
  end

  def extractFilename (fullPath)
    fullPath =~ /^(.*\/)(.*)$/
    $2
  end

  def copyTempPath (tempPath)
    dir = @@imgDir + "tmp/"
    filename = extractFilename tempPath
    filename = @fileManager.uniqueFilename(dir, filename)
    newtempPath = dir + filename
    @fileManager.copy(tempPath, newtempPath)
    newtempPath
  end

  def cleanUp
		if @tempPath && @desiredFilename != ''
			fullPath = @@imgDir + @desiredFilename
			@fileManager.move (@tempPath, fullPath)
			@fileManager.chmod fullPath, 0666
		end
  end
end
