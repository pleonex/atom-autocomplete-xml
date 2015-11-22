xsd = require './xsd'

xsdPattern = /xsi:noNamespaceSchemaLocation="(.+)"/
tagPattern = /<([\.\-_a-zA-Z0-9]*)(?:\s|$)/

module.exports =
  # Enable for XML but not for XML comments.
  selector: '.text.xml'
  disableForSelector: '.text.xml .comment'

  # Take priority over the default provider.
  inclusionPriority: 1
  excludeLowerPriority: true

  # The XSD objects
  latestXsdUrl: ''

  # Return a promise, an array of suggestions, or null.
  getSuggestions: (options) ->
    new Promise (resolve) =>
      @loadXsd options, =>
        if @isTagName(options)
          @getTagNameCompletions(options, resolve)
        else
          []

  loadXsd: ({editor}, complete) ->
    # Get the XSD url
    txt = editor.getText()
    found = txt.match(xsdPattern)

    # If not found, clean and exit
    if not found
      xsd.clear()
      return

    # Load the file
    xsd.load(found[1], complete)

  isTagName: ({prefix, scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    scopes.indexOf('entity.name.tag.localname.xml') isnt -1 or
      prefix is '<'
    return true

  getTagNameCompletions: ({editor, bufferPosition}, resolve) ->
    resolve(xsd.getChildren(@getPreviousTag(editor, bufferPosition)))

  getPreviousTag: (editor, bufferPosition) ->
    {row} = bufferPosition
    while row >= 0
      tag = editor.lineTextForBufferRow(row).match(tagPattern)?[1]
      return tag if tag
      row--
    return null