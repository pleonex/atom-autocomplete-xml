provider = require './provider'
utils = require './xml-utils'

module.exports =
  xpathView: null

  config:
    showXPathInStatusBar:
      title: 'Show XPath In Status Bar'
      description: 'Show in the status bar the current XPath for XML files.'
      type: 'boolean'
      default: true

    addClosingTag:
      title: 'Add Closing Tag'
      description: 'When enabled the closing tag is inserted too.'
      type: 'boolean'
      default: true

  getProvider: -> provider

  activate: (state) ->
    {CompositeDisposable} = require 'atom'
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'autocomplete-xml:copy-XPath-to-clipboard': => @copyXpathToClipboard()

  deactivate: ->
    @xpathView?.destroy()
    @xpathView = null
    @subscriptions?.dispose()
    @subscription = null

  consumeStatusBar: (statusBar) ->
    XPathStatusBarView = require './xpath-statusbar-view'
    @xpathView = new XPathStatusBarView().initialize(statusBar)
    @xpathView.attach()

  copyXpathToClipboard: ->
    editor = atom.workspace.getActiveTextEditor()
    if editor
      buffer = editor.getBuffer()
      bufferPosition = editor.getCursorBufferPosition()
      xpath = utils.getXPathCompleteWord buffer, bufferPosition
      atom.clipboard.write(xpath.join '/')
