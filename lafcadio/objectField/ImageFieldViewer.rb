require 'lafcadio/objectField/FieldViewer'

class ImageFieldViewer < FieldViewer
	def imgTag
		require 'lafcadio/html/IMG'
		path = "/img/#{@value}"
		if @value =~ /\.swf$/
			tag = <<-TAG
<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=5,0,0,0" width="100" height="200">
    <param name=movie value="#{path}">
    <param name=quality value=high>
    <embed src="#{path}" quality=high pluginspage="http://www.macromedia.com/shockwave/download/index.cgi?P1_Prod_Version=ShockwaveFlash" type="application/x-shockwave-flash" width="100" height="200">
    </embed> 
  </object>
			TAG
			tag
		else
			HTML::IMG.new({ 'src' => "#{path}" })
		end
	end

	def currentImageHTML
		require 'lafcadio/html/HTML'
		if @value != nil
			html = HTML::HTML.new
			html << "current #{StrUtil.decapitalize(@field.englishName)}:"
			html.addP
			html << imgTag
			html.addP
			html
		else
			nil
		end
	end

  def toHTMLWidget (fieldType = @field.type)
		require 'lafcadio/html/InputHidden'
    widget = "<input type='file' name='#{@field.name}'>"
    if @value != nil
			hidden = HTML::InputHidden.new({ 'name' => "#{@field.name}.prev",
																			 'value' => @value })
			widget += hidden.toHTML + "\n"
    end
    widget
  end
end

