require 'lafcadio/objectField/LinkField'
require 'lafcadio/objectField/SubsetLinkFieldViewer'

class SubsetLinkField < LinkField
  def SubsetLinkField.viewerType
    SubsetLinkFieldViewer
  end

  attr_accessor :subsetField

  def initialize(objectType, linkedType, subsetField,
      name = linkedType.name.downcase, englishName = nil)
    super(objectType, linkedType, name, englishName)
    @subsetField = subsetField
  end
end