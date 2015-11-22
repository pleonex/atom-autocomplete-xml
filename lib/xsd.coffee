http = require 'http'
xml2js = require 'xml2js'

module.exports =
  lastUrl: ''
  types: {}

  clear: ->
    @lastUrl = ''
    @complexTypes = {}

  load: (xsdUrl, complete) ->
    # If we have already process it, do not load again
    if xsdUrl == @lastUrl
      complete()
      return

    # Download the file
    http.get xsdUrl, (res) =>
      body = ''
      res.on 'data', (chunk) ->
        body += chunk;

      # On complete, parse as XML
      res.on 'end', =>
        xml2js.parseString body, {
          tagNameProcessors: [xml2js.processors.stripPrefix] # Strip nm prefix
          }, (err, result) =>
            @lastUrl = xsdUrl
            @parse(result, complete)

  parse: (xml, complete) ->
    console.log(xml)
    xml = xml.schema

    # Process all ComplexTypes
    @parseComplexType node for node in xml.complexType

    # TODO: Process all SimpleType
    # TODO: Process all AttributeGroup
    # TODO: Process the root node (Element)
    # TODO: Process all Group
    complete()

  normalizeString: (str) ->
    str.replace(/[\n\r]/, '').trim() if str

  parseComplexType: (node) ->
    name = node.$.name
    type =
      # XSD params
      xsdType: 'complex'
      xsdTypeName: name
      xsdAttributes: []
      xsdChildrenMode: ''
      xsdChildren: []

      # Autocomplete params
      text: ''  # Set later
      description: @normalizeString node.annotation?[0].documentation[0]._
      type: 'tag'
      rightLabel: 'Tag'

    # Parse the child elements
    childrenNode = null
    if node.sequence
      type.xsdChildrenMode = 'sequence'
      childrenNode = node.sequence[0]
    else if node.choice
      type.xsdChildrenMode = 'choice'
      childrenNode = node.choice[0]
    else if node.all
      type.xsdChildrenMode = 'all'
      childrenNode = node.all[0]

    # We can found element, choice or sequence inside a sequence, choice or all
    if childrenNode
      type.xsdChildren =
        (@parseChild child for child in (childrenNode.element ? []))
        .concat((@parseSubChildren childrenNode.choice, 'choice'))
        .concat((@parseSubChildren childrenNode.sequence, 'sequence'))

    # TODO: Parse attributes

    @types[name] = type

  parseChild: (node) ->
    child =
      tagName: node.$.name
      xsdType: node.$.type
      minOccurs: node.$.minOccurs ? 0
      maxOccurs: node.$.maxOccurs ? 'unbounded'
      description: @normalizeString node.annotation?[0].documentation[0]._

  parseSubChildren: (node, mode) ->
    if not node
      return []

    children = []
    for subNode in node
      child =
        description: @normalizeString subNode.annotation?[0].documentation[0]._
        nodeMode: mode
        nodes: []

      # We don't support more recursive levels -> check only for elements
      for subSubNode in (subNode.element ? [])
        child.nodes.push @parseChild subSubNode
      children.push child
    return children

  getChildren: (name) ->
    # From the tag name get the type name
    typeName = @searchTypeName(name)

    # Create list of suggestions from childrens
    suggestions = []
    for child in @types[typeName].xsdChildren
      if child.nodes
        suggestions.push @createSuggestion c for c in child.nodes
      else
        suggestions.push @createSuggestion child

    suggestions.filter (n) -> n != undefined

  searchTypeName: (tagName) ->
    # Search inside the types
    for name, value of @types
      for child in value.xsdChildren
        if child.nodes
          (return c.xsdType if c.tagName == tagName) for c in child.nodes
        else
          return child.xsdType if child.tagName == tagName

  createSuggestion: (child) ->
    sug = @types[child.xsdType]
    sug?.text = child.tagName
    sug?.description = child.description ? sug.description
    return sug
