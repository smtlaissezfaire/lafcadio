require 'lafcadio/objectField/FieldViewer'
require 'lafcadio/html/JSIfElseTree'
require 'lafcadio/html/Select'

class LinkFieldViewer < FieldViewer
  def getBroadcastJavaScriptFunctionName
    "set#{@field.listener.name.capitalize}Default"
  end

  def javaScriptFunction
    if @field.listener != nil
      functionName = getBroadcastJavaScriptFunctionName
      ifElseTree = HTML::JSIfElseTree.new
      ObjectStore.getObjectStore.getAll(@field.linkedType).each { |object|
        condition = "triggerValue == #{object.objId}"
        defaultValue = object.send(@field.listener.defaultFieldName)
        statement = "setValue = #{defaultValue}"
        ifElseTree.addPair(condition, statement)
      }
      aFunction = "function #{functionName} (triggerField) {\n" +
	  "triggerValue = triggerField.value;\nsetValue = 0;\n" +
	  "#{ifElseTree.toJavaScript}\n"
	  "document.ae.#{@field.listener.name}.value = setValue;\n}"
      aFunction
    else
      ""
    end
  end

  def getObjId
    @value != nil ? @value.objId : nil
  end

  def optionObjs
		optionObjs = ObjectStore.getObjectStore.getAll(@field.linkedType)
		if @field.linkedType == @field.objectType
			optionObjs = optionObjs.removeObjects("objId", @objId)
		end
		optionObjs.sort! ( [@field.sortField || 'objId'] )
		optionObjs
  end

  def toHTMLWidget
    select = HTML::Select.new({ 'name' => @field.name })
		select.selected = getObjId
    if @field.listener != nil
      select.onChange = "#{getBroadcastJavaScriptFunctionName}(this)"
    end
    select.addOption("", "") unless @field.notNull
    optionObjs.each { |obj| select.addOption(obj.objId, obj.name) }
		if @field.newDuringEdit
	    select.addOption("new", "new #{@field.linkedType.englishName} ...")
		end
    select.toHTML
  end

	def toAeFormRows
		if @field.linkedType != User
			super
		else
			[]
		end
	end
end

