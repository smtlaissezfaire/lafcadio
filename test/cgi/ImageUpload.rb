require 'lafcadio/cgi/ImageUpload'
require 'lafcadio/test/LafcadioTestCase'
require 'tempfile'
require 'lafcadio/mock/MockFileManager'

class TestImageUpload < LafcadioTestCase
  def setup
    @tempfile = Tempfile.new "image"
    def @tempfile.original_filename
      "john.jpg"
    end
    def @tempfile.local_path
      "/tmp/CGI1.2"
    end
    def @tempfile.content_type
      "image/jpeg"
    end
    @mFileManager = MockFileManager.new
    @mFileManager.addFile("/tmp/", "CGI1.2")
    @imgUpload = ImageUpload.new @tempfile, @mFileManager
  end

  def testCopiesOnInitialize
    assert @imgUpload.tempPath != @tempfile.local_path
    @imgUpload.tempPath =~ /^(.*\/)(.*)$/
    assert @mFileManager.exists($1, $2)
    assert_equal "../img/tmp/", $1
  end

  def testRemovesFileOnCleanUp
    @imgUpload.cleanUp
    @imgUpload.tempPath =~ /^(.*\/)(.*)$/
    assert !@mFileManager.exists($1, $2)
  end

  def testStripsOutSpaces
    tempfile = Tempfile.new "image"
    def tempfile.original_filename
      "john.jpg 1"
    end
    def tempfile.local_path
      "/tmp/CGI1.2"
    end
    def tempfile.content_type
      "image/jpeg"
    end
    imgUpload = ImageUpload.new tempfile, @mFileManager
    assert_nil imgUpload.desiredFilename.index(" ")
  end

  def testPutsExtensionOnFiles
    tempfile = Tempfile.new "img"
    def tempfile.local_path
      "/tmp/tmpfile"
    end
    def tempfile.original_filename
      "john"
    end
    def tempfile.content_type
      "image/jpeg"
    end
    imgUpload = ImageUpload.new tempfile, @mFileManager
    assert_equal "john_1.jpg", imgUpload.desiredFilename
    def tempfile.content_type
      "image/gif"
    end
    imgUpload = ImageUpload.new tempfile, @mFileManager
    assert_equal "john.gif", imgUpload.desiredFilename
  end

  def testCleanUpCopiesFileOutOfTempDir
    @imgUpload.cleanUp
    assert @mFileManager.exists ("../img/", "john.jpg")
  end

	def testCleanUpChmod0666
		@imgUpload.cleanUp
		assert_equal (0666, @mFileManager.perms["../img/john.jpg"])
	end

	def testEmptyDoesntDoAnythingDuringCleanup
		tf = Tempfile.new ""
		def tf.local_path
			""
		end
		iu = ImageUpload.new (Tempfile.new(""), @mFileManager)
		iu.cleanUp
	end
end
