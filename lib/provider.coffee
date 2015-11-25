xsd = require './xsd'

xsdPattern = /xsi:noNamespaceSchemaLocation="(.+)"/

# This will catch:
# * Start tags: <tagName
# * End tags: </tagName
# * Auto close tags: />
tagFullPattern = /(<\/\s*[\.\-_a-zA-Z0-9]+|<\s*[\.\-_a-zA-Z0-9]+|\/>)/


module.exports =
  # Enable for XML but not for XML comments.
  selector: '.text.xml'
  disableForSelector: '.text.xml .comment'

  # Take priority over the default provider.
  inclusionPriority: 1
  excludeLowerPriority: true


  # Return a promise, an array of suggestions, or null.
  getSuggestions: (options) ->
    new Promise (resolve) =>
      @loadXsd options, =>
        if @isTagName(options)
          @getTagNameCompletions(options, resolve)


  ## Load the XSD and build the types tree.
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


  ## Checks if the current curso is on a incomplete tag name.
  isTagName: ({prefix, scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    scopes.indexOf('entity.name.tag.localname.xml') isnt -1 or
      prefix is '<'
    # TODO: Fix tag detection when writing just "<".
    return true


  ## Get the tag name completion.
  getTagNameCompletions: ({editor, bufferPosition}, resolve) ->
    console.log @getXPath editor, bufferPosition
    resolve []
    #resolve(xsd.getChildren(@getPreviousTag(editor, bufferPosition)))


  ## Get the full XPath to the current tag.
  getXPath: (editor, bufferPosition) ->
    # TODO: Start in the middle of a tag name.
    # For every row, checks if it's an open, close, or autoopenclose tag and
    # update a list of all the open tags.
    {row} = bufferPosition
    xpath = []
    skipList = []
    waitingStartTag = false
    while row >= 0
      line = editor.lineTextForBufferRow(row--)

      # Apply the regex expression, read from right to left and remove first.
      matches = line.match(tagFullPattern)
      matches?.shift()
      matches?.reverse()

      for match in matches ? []
          # Auto tag close
          if match == "/>"
              waitingStartTag = true
          # End tag
          else if match[0] == "<" && match[1] == "/"
              skipList.push match.slice 2
          # This should be a start tag
          else if match[0] == "<" && waitingStartTag
              waitingStartTag = false
          else if match[0] == "<"
              tagName = match.slice 1
              idx = skipList.lastIndexOf tagName
              if idx != -1 then skipList.splice idx, 1 else xpath.push tagName


    return xpath.reverse()
