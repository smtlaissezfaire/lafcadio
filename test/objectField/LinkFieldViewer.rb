require 'test/mock/domain/Client'
require 'lafcadio/objectField/LinkField'
require 'lafcadio/test/LafcadioTestCase'

class TestLinkFieldViewer < LafcadioTestCase
  def setup
  	super
    @fieldWithListener = LinkField.new (nil, Client, "client", "Client")
    rateField = MoneyField.new nil, "rate"
    rateField.setDefault(@fieldWithListener, "standard_rate")
  end

  def testHTMLWidgetSet
    @mockObjectStore.addObject Client.new( { "objId" => 1, "name" => "clientName1" } )
    @mockObjectStore.addObject Client.new( { "objId" => 2, "name" => "clientName2" } )
    olf = LinkField.new(nil, Client, "client", "Client")
    client = Client.new( { "objId" => 1, "name" => "clientName1" } )
		html = olf.viewer(client, nil).toHTMLWidget
    assert_not_nil(html.index(
				"<option value='1' selected>clientName1</option>"), html)
    assert_not_nil(html.index("<option value='2'>clientName2</option>"))
    assert_not_nil html.index(">new client ...<")
  end

  def testJavaScriptFunction
		js = @fieldWithListener.viewer(nil, nil).javaScriptFunction
    assert_not_nil(js.index("setRateDefault (triggerField)"))
  end

  def testHTMLWidgetForListenedField
		html = @fieldWithListener.viewer(nil, nil).toHTMLWidget
    assert_not_nil(html.index("onChange='setRateDefault(this)'"), html)
  end

  def testWithoutListener
    olf = LinkField.new(nil, Client)
		olf.viewer(nil, nil).javaScriptFunction
  end

  def testNullOption
    olf = LinkField.new (nil, Client, "client", "Client")
    olf.notNull = false
		html = olf.viewer(nil, nil).toHTMLWidget
    assert_not_nil html.index("<option value=''>")
  end

	def testNewDuringEditIsFalse
		olf = LinkField.new (nil, Client, "client", "Client")
		olf.newDuringEdit = false
		html = olf.viewer(nil, nil).toHTMLWidget
		assert_nil html.index("new client ..."), html
	end

	def testCantSelfLink
		client1 = Client.storedTestClient
		client2 = Client.new( { "name" => 'clientName2', 'objId' => 2 } )
		@mockObjectStore.addObject client2
		referringClientField = Client.getField 'referringClient'
		html = referringClientField.viewer(nil, 1).toHTMLWidget
		assert_nil html.index('clientName1')
	end
end