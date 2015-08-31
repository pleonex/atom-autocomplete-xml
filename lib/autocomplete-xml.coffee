AutocompleteXmlView = require './autocomplete-xml-view'
{CompositeDisposable} = require 'atom'

module.exports = AutocompleteXml =
  autocompleteXmlView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @autocompleteXmlView = new AutocompleteXmlView(state.autocompleteXmlViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @autocompleteXmlView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'autocomplete-xml:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @autocompleteXmlView.destroy()

  serialize: ->
    autocompleteXmlViewState: @autocompleteXmlView.serialize()

  toggle: ->
    console.log 'AutocompleteXml was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
