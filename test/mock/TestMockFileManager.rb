require 'lafcadio/test/LafcadioTestCase'

class TestMockFileManager < LafcadioTestCase
	def setup
		@mfm = MockFileManager.new
	end

	def testCTime
		preTime = Time.now
		@mfm.touch("cache/product5.xml.lock")
		postTime = Time.new
		ctime = @mfm.ctime("cache/product5.xml.lock")
		assert preTime < ctime
		assert postTime > ctime
	end

	def testCTimeForWrite
		xmlFullPath = "cache/product5.xml"
		preTime = Time.new
		@mfm.write(xmlFullPath, "<product></product>")
		postTime = Time.now
		ctime = @mfm.ctime(xmlFullPath)
		assert preTime < ctime
		assert postTime > ctime
	end

	def testSave
		xmlStr = "<product></product>"
		xmlFullPath = "cache/product5.xml"
		@mfm.save (xmlFullPath, xmlStr)
		assert_equal xmlStr, (@mfm.read (xmlFullPath))
	end

	def testWrite
		testData = "The quick brown fox"
		testPath = "test.dat"
		@mfm.write (testPath, testData)
		assert_equal testData, @mfm.read(testPath)
	end

	def testDelete
		path = "cache/product5.xml.lock"
		@mfm.touch (path)
		@mfm.delete path
		assert !@mfm.exists("cache", 'product5.xml.lock')
	end

	def testCopy
		@mfm.copy ("test/file.new", "test/tile")
	end
end