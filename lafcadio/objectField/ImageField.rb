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
end

