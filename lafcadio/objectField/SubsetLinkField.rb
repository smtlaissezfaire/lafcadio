require 'lafcadio/objectField/LinkField'

class SubsetLinkField < LinkField
  def SubsetLinkField.instantiationParameters( fieldElt )
		parameters = super( fieldElt )
		parameters['subsetField'] = fieldElt.attributes['subsetField']
		parameters
  end
  
  def SubsetLinkField.instantiateWithParameters( domainClass, parameters )
		self.new( domainClass, parameters['linkedType'], parameters['subsetField'],
		          parameters['name'], parameters['englishName'] )
  end

  attr_accessor :subsetField

  def initialize(objectType, linkedType, subsetField,
      name = linkedType.name.downcase, englishName = nil)
    super(objectType, linkedType, name, englishName)
    @subsetField = subsetField
  end
end