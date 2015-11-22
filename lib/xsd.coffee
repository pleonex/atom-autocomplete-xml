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
    suggestions = []
    for child in @types[typeName].xsdChildren
      if child.nodes
        suggestions.push @createSuggestion c for c in child.nodes
      else
        suggestions.push @createSuggestion child

    suggestions.filter (n) -> n != undefined


  ## Search for the XSD type name by using the tag name.
  searchTypeName: (tagName) ->
    # TODO: This is not a valid approach since we can found same tag name
    # from different parents pointing to different XSD types. Do XPath query.

    for name, value of @types
      for child in value.xsdChildren
        if child.nodes
          (return c.xsdType if c.tagName == tagName) for c in child.nodes
        else
          return child.xsdType if child.tagName == tagName


  ## Create a suggestion object from a child object.
  createSuggestion: (child) ->
    sug = @types[child.xsdType]
    sug?.text = child.tagName
    sug?.description = child.description ? sug.description
    return sug
