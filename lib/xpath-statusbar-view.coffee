{Disposable} = require 'atom'
utils = require './xml-utils'

# XPath view in the status Bar.
# Create a label and append to the StatusBar. In order to update the content,
# subscribe to active panel changes and inside that to
# TextEditor cursor changes.
class XPathStatusBarView extends HTMLDivElement
  statusBar: null                 # The status bar.
  xpathLabel: null                # StatusBar label for XPath.
  tile: null                      # Tile object appended to the StatusBar.
  xpathSubscription: null         # TextEditor content change subscription.
  activeItemSubscription: null    # Active panel change subscription.
  configurationSubscription: null # Configuration change subscription.

  ## Constructor: create the label and append to the div.
  initialize: (statusBar) ->
    @statusBar = statusBar
    @classList.add('xpath-status', 'inline-block')  # Class is inline-block.
    @xpathLabel = document.createElement('label')   # Object will be label.
    @appendChild(@xpathLabel)                       # Append the label to div.
    @handleEvents()
    this

  ## Destroy all the components.
  destroy: ->
    @disposeViewSubscriptions()

    # Dispose the subscription to panel changes.
    @activeItemSubscription?.dispose()
    @activeItemSubscription = null

    # Destroy the configuration change subscription.
    @configurationSubscription?.dispose()
    @configurationSubscription = null

    # Destroy the tile StatusBar object.
    @tile?.destroy()
    @tile = null

  ## Subscribe to configuration chages and panel changes.
  handleEvents: ->
    # Check for current panel active changes to attach listeners.
    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem =>
      @subscribeToActiveTextEditor()

    # Check for configuration changes.
    @configurationSubscription = atom.config.observe(
      'autocomplete-xml.showXPathInStatusBar', => @attach())

    # And attach subscriber to the current panel if it's a TextEditor.
    @subscribeToActiveTextEditor()

  ## Attach the view to the status bar.
  attach: ->
    # Destroy the current StatusBar object.
    @tile?.destroy()

    if atom.config.get 'autocomplete-xml.showXPathInStatusBar'
      # Append to the statusBar a new.
      @tile = @statusBar.addRightTile(item: this)
    else
      # Disable -> dispose everything if it was created previously.
      @disposeViewSubscriptions()
    return @tile

  ## Dispose the subscription events of the view.
  disposeViewSubscriptions: ->
    # Dispose the subscription to text editor changes.
    @xpathSubscription?.dispose()
    @xpathSubscription = null

  ## Helper method to get the current TextEditor if any.
  getActiveTextEditor: ->
    atom.workspace.getActiveTextEditor()

  ## Subscribe the event ChangeCursor to update the XPath.
  subscribeToActiveTextEditor: ->
    @xpathSubscription?.dispose()

    # Only if it's an XML file.
    if @getActiveTextEditor()?.getGrammar()?.name == "XML"
      @updateXPath()
      @xpathSubscription = @getActiveTextEditor()?.onDidChangeCursorPosition =>
        @updateXPath()
    else
      @xpathLabel.textContent = ''

  ## Update the content of the label with the current XPath if any.
  updateXPath: ->
    editor = @getActiveTextEditor()
    if editor
      buffer = editor.getBuffer()
      bufferPosition = editor.getCursorBufferPosition()
      xpath = utils.getXPathCompleteWord buffer, bufferPosition
      @xpathLabel.textContent = xpath.join '/'
    else
      @xpathLabel.textCotent = ''

  ## Shortcut for copying xpath to clipboard 
  copyToClipboard: ->
      if editor = atom.workspace.getActiveTextEditor()
          if Utils.confirmFileType(editor, 'xml')
              atom.clipboard.write(xpath.join '/')

## Register the class into the document to be available.
module.exports =
  document.registerElement(
    'xpath-statusbar',
    prototype: XPathStatusBarView.prototype)
