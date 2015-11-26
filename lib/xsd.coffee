http = require 'http'
xsdParser = require './xsdParser'

module.exports =
  types: {}


  ## Clear the data. This is the case of changing the XSD.
  clear: ->
    @types = {}


  ## Load a new XSD.
  load: (xsdUrl, complete) ->
    # Download the file
    # TODO: Read disk files too.
    http.get xsdUrl, (res) =>
      body = ''
      res.on 'data', (chunk) ->
        body += chunk;

      # On complete, parse XSD
      res.on 'end', =>
        @lastUrl = xsdUrl
        @types = xsdParser.types
        xsdParser.parseFromString(body, complete)


  ## Called when suggestion requested. Get all the possible node children.
  getChildren: (xpath) ->
    # Get the XSD type name from the tag name.
    type = @findTypeFromXPath xpath

    # Create list of suggestions from childrens
    # TODO: Represent groups in autocompletion
    suggestions = []
    for group in type.xsdChildren
      suggestions.push @createSuggestion element for element in group.elements

    # Remove undefined elements (e.g.: non-supported yet types).
    suggestions.filter (n) -> n != undefined


  ## Search the type from the XPath
  findTypeFromXPath: (xpath) ->
    type = xsdParser.root
    xpath.shift()  # Remove root node.

    while xpath && xpath.length > 0
      nextTag = xpath.shift()
      nextTypeName = @findTypeFromTag nextTag, type
      type = @types[nextTypeName]

    return type


  ## Search for the XSD type name by using the tag name.
  findTypeFromTag: (tagName, node) ->
    for group in node.xsdChildren
      for el in group.elements
        return el.xsdType if el.tagName == tagName


  ## Create a suggestion object from a child object.
  createSuggestion: (child) ->
    # The suggestion is a merge between the general type info and the
    # specific information from the child object.
    sug = null
    if child.xsdType
      sug = @types[child.xsdType]
      sug?.text = child.tagName
      sug?.description = child.description ? sug.description
    else
      sug =
        text: child.tagName
        type: 'value'
        rightLabel: 'Value'
    return sug
