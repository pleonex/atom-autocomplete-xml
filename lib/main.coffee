provider = require './provider'

module.exports =
  xpathView: null

  getProvider: -> provider

  deactivate: ->
    @xpathView?.destroy()
    @xpathView = null

  consumeStatusBar: (statusBar) ->
    XPathStatusBarView = require './xpath-statusbar-view'
    @xpathView = new XPathStatusBarView().initialize(statusBar)
    @xpathView.attach()
