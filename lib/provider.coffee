xsdPattern = /xsi:noNamespaceSchemaLocation="(.+)"/

module.exports =
  # Enable for XML but not for XML comments.
  selector: '.text.xml'
  disableForSelector: '.text.xml .comment'

  # Take priority over the default provider.
  inclusionPriority: 1
  excludeLowerPriority: true

  latestXsdUrl: ''
  xsd: null

  # Return a promise, an array of suggestions, or null.
  getSuggestions: (options) ->
    @loadXsd(options)

    if @isTagName(options)
      @getTagNameCompletions(options)
    else
      []

  loadXsd: ({editor, bufferPosition}) ->
    # Get the XSD url
    txt = editor.getTextInBufferRange([[0, 0], bufferPosition])
    found = txt.match(xsdPattern)

    # If not found, clean the latest XSD url (removed?) and exit
    if not found
      latestXsdUrl = ''
      xsd = null
      return

    # If we have already process it, do not load again
    if found[1] == latestXsdUrl
      return

    # Get the file
    latestXsdUrl = found[1]
    # TODO: Download and process

  isTagName: ({prefix, scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    scopes.indexOf('entity.name.tag.localname.xml') isnt -1

  getTagNameCompletions: ({editor, bufferPosition}) ->
    new Promise (resolve) ->
      sug1 =
        text: 'something'
      sug2 =
        text: 'otherthing'
      resolve([sug1, sug2])
