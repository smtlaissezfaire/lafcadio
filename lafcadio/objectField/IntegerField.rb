require 'lafcadio/objectField/ObjectField'

class IntegerField < ObjectField
  def textBoxSize
    5
  end

	def valueFromSQL (string)
		value = super
		value ? value.to_i : nil
	end
end