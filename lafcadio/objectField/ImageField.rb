require 'lafcadio/objectField/ObjectField'
require 'lafcadio/util/FileManager'

class ImageField < ObjectField
  @@imgDir = "../html/img/"

  def initialize(objectType, name = "image", englishName = nil,
      fileManager = FileManager)
    super objectType, name, englishName
    @fileManagerClass = fileManager
  end

  def valueForSQL(value)
    "'#{value}'"
  end

  def valueAsHTML(dbObject)
		require 'lafcadio/html/IMG'
    filename = super dbObject
		if filename != "" && filename != nil
			HTML::IMG.new({ 'src' => "/img/#{filename}" }).toHTML
		else
			""
		end
  end
end

