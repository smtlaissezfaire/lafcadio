require 'lafcadio/objectField/ObjectField'
require 'lafcadio/util/FileManager'

class ImageField < ObjectField
  def ImageField.viewerType
		require 'lafcadio/objectField/ImageFieldViewer'
    ImageFieldViewer
  end

  @@imgDir = "../html/img/"

  def initialize (objectType, name = "image", englishName = nil,
      fileManager = FileManager)
    super objectType, name, englishName
    @fileManagerClass = fileManager
  end

  def valueFromCGI (fieldManager)
		require 'lafcadio/cgi/ImageUpload'
		value = super fieldManager
		if value.type <= ImageUpload
      if value.desiredFilename == ""
        value = fieldManager.get("#{name}.prev")
        if value == nil
          if firstTime (fieldManager)
            value = nil
          else
            value = prevValue fieldManager.getObjId
          end
        end
      else
        value = value.desiredFilename
      end
    end
    value
  end

  def valueForSQL (value)
    "'#{value}'"
  end

  def valueAsHTML (dbObject)
		require 'lafcadio/html/IMG'
    filename = super dbObject
		if filename != "" && filename != nil
			HTML::IMG.new({ 'src' => "/img/#{filename}" }).toHTML
		else
			""
		end
  end
end

