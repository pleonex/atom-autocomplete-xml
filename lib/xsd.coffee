http = require 'http'
xsdParser = require './xsdParser'

module.exports =
  lastUrl: ''
  types: {}


  ## Clear the data. This is the case of changing the XSD.
  clear: ->
    @lastUrl = ''
    @types = {}


  ## Load a new XSD.
  load: (xsdUrl, complete) ->
    # If we have already process it, do not load again
    if xsdUrl == @lastUrl
      complete()
      return

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
  getChildren: (name) ->
    # Get the XSD type name from the tag name.
    typeName = @searchTypeName(name)
    if not typeName
      return []

    # Create list of suggestions from childrens
    # TODO: Represent groups in autocompletion
    suggestions = []
    for group in @types[typeName].xsdChildren
      suggestions.push @createSuggestion element for element in group.elements

    # Remove undefined elements (e.g.: non-supported yet types).
    suggestions.filter (n) -> n != undefined


  ## Search for the XSD type name by using the tag name.
  searchTypeName: (tagName) ->
    # TODO: This is not a valid approach since we can found same tag name
    # from different parents pointing to different XSD types. Do XPath query.

    for name, value of @types
      for group in value.xsdChildren
        for el in group.elements
          return el.xsdType if el.tagName == tagName


  ## Create a suggestion object from a child object.
  createSuggestion: (child) ->
    # The suggestion is a merge between the general type info and the
    # specific information from the child object.
    sug = @types[child.xsdType]
    sug?.text = child.tagName
    sug?.description = child.description ? sug.description
    return sug
