require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/util/FileManager'

class TestFileManager < LafcadioTestCase
	def testWriteOverwrites
		testFilePath = 'test/testData/test.txt'
		File.open( testFilePath, File::CREAT | File::TRUNC | File::WRONLY ) { |file|
			file.puts( "aaaaa" )
		}
		assert_equal( "aaaaa\n", FileManager.read( testFilePath ) )
		FileManager.write( testFilePath, 'bbb' )
		assert_equal( "bbb\n", FileManager.read( testFilePath ) )
	end
end