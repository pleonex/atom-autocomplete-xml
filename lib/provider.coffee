xsd = require './xsd'

xsdPattern = /xsi:noNamespaceSchemaLocation="(.+)"/

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

  loadXsd: ({editor, bufferPosition}, complete) ->
    # Get the XSD url
    txt = editor.getTextInBufferRange([[0, 0], bufferPosition])
    found = txt.match(xsdPattern)

    # If not found, clean the latest XSD url (removed?) and exit
    if not found
      @latestXsdUrl = ''
      return

    # If we have already process it, do not load again
    if found[1] == @latestXsdUrl
      return

    # Get the file
    xsd.constructor(found[1], complete)

  isTagName: ({prefix, scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    scopes.indexOf('entity.name.tag.localname.xml') isnt -1

  getTagNameCompletions: ({editor, bufferPosition}, resolve) ->
    # TODO: Get previous tag.
    resolve(xsd.getChildren("Participant"))
