require 'lafcadio/domain'
require 'lafcadio/objectField'

class XmlSku2 < Lafcadio::DomainObject
	boolean    'boolean1',
	           { 'enumType' => Lafcadio::BooleanField::ENUMS_CAPITAL_YES_NO }
	boolean    'boolean2',
	           { 'enums' => { true => 'yin', false => 'yang' },
		           'englishName' => 'boolean 2' }
	date       'date1', { 'notNull' => false }
	date       'date2', { 'range' => Lafcadio::DateField::RANGE_PAST }
	dateTime   'dateTime1'
	decimal    'decimal1', { 'precision' => 4, 'englishName' => 'decimal 1' }
	email      'email1'
	enum       'enum1',
	           { 'enums' => Lafcadio::QueueHash.new( 'a', 'a', 'b', 'b' ) }
	enum       'enum2',
	           { 'enums' => Lafcadio::QueueHash.new( '1', '2', '3', '4' ) }
	integer    'integer1'
	link       'link1', { 'linkedType' => User, 'deleteCascade' => true }
	money      'money1'
	month      'month1'
	subsetLink 'subsetLink1', { 'subsetField' => 'xmlSku' }
	text       'text1', { 'size' => 16, 'unique' => true }
	text       'text2', { 'large' => true }
	textList   'textList1', { 'dbFieldName' => 'text_list1' }
	timeStamp  'timestamp1'
end
