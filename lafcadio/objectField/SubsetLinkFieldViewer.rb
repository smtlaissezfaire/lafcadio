require 'lafcadio/objectField/LinkFieldViewer'

class SubsetLinkFieldViewer < LinkFieldViewer
  def keepObjsLinkedToMe (optionObjs)
    optionObjs.filterByBlock { |obj|
      subsetFieldValue = obj.send(@field.subsetField)
      if subsetFieldValue != nil
				otherObjLinkId = subsetFieldValue.objId
      else
				otherObjLinkId = nil
      end
      otherObjLinkId == @objId
    }
  end

  def optionObjs
    keepObjsLinkedToMe super
  end

  def toAeFormRows
    if @objId == nil
      []
    else
      super
    end
  end
end
