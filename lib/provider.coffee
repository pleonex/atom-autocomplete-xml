xsd = require './xsd'
utils = require './xml-utils'

xsdPattern = /xsi:noNamespaceSchemaLocation="(.+)"/

module.exports =
  # Enable for XML but not for XML comments.
  selector: '.text.xml'
  disableForSelector: '.text.xml .comment'

  # Take priority over the default provider.
  inclusionPriority: 1
  excludeLowerPriority: true

  # Last XSD url loaded - Load only once the XSD.
  # TODO: Create cache of XSDs.
  lastXsdUri: ''


  # Return a promise, an array of suggestions, or null.
  getSuggestions: (options) ->
    newUri = @getXsdUri options

    # If we don't found a URI maybe the file does not have XSD. Clean and exit.
    if not newUri
      @lastXsdUri = ''
      xsd.clear()
      []
    else if newUri == @lastXsdUri
      @detectAndGetSuggestions options
    else
      @lastXsdUri = newUri
      new Promise (resolve) =>
        xsd.load options.editor.getPath(), newUri, =>
          resolve @detectAndGetSuggestions options


  detectAndGetSuggestions: (options) ->
    if @isTagName options
      @getTagNameCompletions options
    else if @isCloseTagName options
      @getCloseTagNameCompletion options
    else if @isTagValue options
      @getValuesCompletions options
    else
      []


  ## Get XSD URI
  getXsdUri: ({editor}) ->
    # Get the XSD url
    txt = editor.getText()
    uri = txt.match(xsdPattern)?[1]


  ## Filter the candidate completions by prefix.
  filterCompletions: (candidate, prefix) ->
    completions = []
    for child in candidate when not prefix or child.text.indexOf(prefix) is 0
      completions.push child
    return completions


  ## Checks if the current cursor is on a incomplete tag name.
  isTagName: ({editor, bufferPosition, scopeDescriptor}) ->
    {row, column} = bufferPosition
    lastChar = editor.getTextInBufferRange([[row, column-1], [row, column]])
    scopes = scopeDescriptor.getScopesArray()
    return scopes.indexOf('entity.name.tag.localname.xml') isnt -1 or
      lastChar is '<'


  ## Get the tag name completion.
  getTagNameCompletions: ({editor, bufferPosition, prefix}) ->
    # Get the children of the current XPath tag.
    children = xsd.getChildren(
      utils.getXPath(editor.getBuffer(), bufferPosition, prefix))

    # Apply a filter with the current prefix and return.
    return @filterCompletions children, prefix


  ## Checks if the current cursor is to close a tag.
  isCloseTagName: ({editor, bufferPosition}) ->
    {row, column} = bufferPosition
    lastTwoChars = editor.getTextInBufferRange([[row, column-2], [row, column]])
    return lastTwoChars is "</"


  ## Get the tag name that close the current one.
  getCloseTagNameCompletion: ({editor, bufferPosition, prefix}) ->
    parentTag = utils.getXPath(editor.getBuffer(), bufferPosition, prefix, 1)[0]
    return [{
      text: parentTag + '>'
      displayText: parentTag
      type: 'tag'
      rightLabel: 'Tag'
    }]


  ## Checks if the current cursor is about complete values.
  isTagValue: ({scopeDescriptor}) ->
    # For multiline values we can only check text.xml
    return scopeDescriptor.getScopesArray().indexOf('text.xml') isnt -1


  ## Get the values of the current XPath tag.
  getValuesCompletions: ({editor, bufferPosition, prefix}) ->
    # Get the children of the current XPath tag.
    children = xsd.getChildren(
      utils.getXPath(editor.getBuffer(), bufferPosition, prefix))

    # Apply a filter with the current prefix and return.
    return @filterCompletions children, prefix
