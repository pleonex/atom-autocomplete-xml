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
      new Promise (resolve) =>
        xsd.load options.editor.getPath(), newUri, =>
          @lastXsdUri = newUri
          resolve @detectAndGetSuggestions options


  detectAndGetSuggestions: (options) ->
    if @isTagName options
      @getTagNameCompletions options
    else if @isCloseTagName options
      @getCloseTagNameCompletion options
    else if @isAttribute options
      @getAttributeCompletions options
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
  filterCompletions: (sugs, prefix) ->
    completions = []
    prefix = prefix?.trim()
    for s in sugs when not prefix or (s.text ? s.snippet).indexOf(prefix) is 0
      completions.push @buildCompletion s
    return completions


  ## Build the completion from scratch. In this way the object doesn't
  ## contain attributes from previous autocomplete-plus processing.
  buildCompletion: (value) ->
    text: value.text
    snippet: value.snippet
    displayText: value.displayText
    description: value.description
    type: value.type
    rightLabel: value.rightLabel
    leftLabel: value.leftLabel


  ## Checks if the current cursor is on a incomplete tag name.
  isTagName: ({editor, bufferPosition, prefix}) ->
    {row, column} = bufferPosition
    tagPos = column - prefix.length - 1
    tagChars = editor.getTextInBufferRange([[row, tagPos], [row, tagPos + 1]])
    return tagChars is '<' or prefix is '<'


  ## Get the tag name completion.
  getTagNameCompletions: ({editor, bufferPosition, prefix}) ->
    # Get the children of the current XPath tag.
    children = xsd.getChildren(
      utils.getXPath(editor.getBuffer(), bufferPosition, prefix))

    # Apply a filter with the current prefix and return.
    return @filterCompletions children, (if prefix is '<' then '' else prefix)


  ## Checks if the current cursor is to close a tag.
  isCloseTagName: ({editor, bufferPosition, prefix}) ->
    {row, column} = bufferPosition
    tagClosePos = column - prefix.length - 2
    tagChars = editor.getTextInBufferRange(
      [[row, tagClosePos], [row, tagClosePos + 2]])
    return tagChars is "</"


  ## Get the tag name that close the current one.
  getCloseTagNameCompletion: ({editor, bufferPosition, prefix}) ->
    parentTag = utils.getXPath(editor.getBuffer(),bufferPosition,prefix,1)
    parentTag = parentTag[parentTag.length - 1]
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
    children = xsd.getValues(
      utils.getXPath(editor.getBuffer(), bufferPosition, prefix))

    # Apply a filter with the current prefix and return.
    return @filterCompletions children, prefix


  ## Checks if the current cursor is about complete attributes.
  isAttribute: ({scopeDescriptor, editor, bufferPosition}) ->
    {row, column} = bufferPosition
    previousChar = editor.getTextInBufferRange([[row, column-1], [row, column]])
    scopes = scopeDescriptor.getScopesArray()
    scopes.indexOf('meta.tag.xml') isnt -1 and previousChar isnt '>'


  ## Get the attributes for the current XPath tag.
  getAttributeCompletions: ({editor, bufferPosition, prefix}) ->
    # Get the attributes of the current XPath tag.
    attributes = xsd.getAttributes(
      utils.getXPath(editor.getBuffer(), bufferPosition, ''))

    # Apply a filter with the current prefix and return.
    return @filterCompletions attributes, prefix
