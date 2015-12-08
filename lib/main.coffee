provider = require './provider'

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

  deactivate: ->
    @xpathView?.destroy()
    @xpathView = null

  consumeStatusBar: (statusBar) ->
    XPathStatusBarView = require './xpath-statusbar-view'
    @xpathView = new XPathStatusBarView().initialize(statusBar)
    @xpathView.attach()
