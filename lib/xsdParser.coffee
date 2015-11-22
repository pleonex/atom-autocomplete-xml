http = require 'http'
xml2js = require 'xml2js'

module.exports =
  # Expected type object from external modules.
  # type:
  #   text: The text for autocomplete. Set externally from child.tagName.
  #   description: Documentation info. It can be empty.
  #   type: The autocomplete type.
  #   rightLabel: The autocomplete right libel. The XML type of element.
  #
  #   xsdTypeName: The name inside the XSD.
  #   xsdChildrenMode: The order of the children: all, sequence or choice.
  #   xsdChildren: References to other types. They are in groups.
  #     childType: The type of children nodes group: element, sequence or choice
  #     minOccurs: The group of children must appear at least...
  #     maxOccurs: The group of children cann't appear more than ...
  #     elements: The elements of the group (they must be elements tags).
  #       tagName: The name of the tag.
  #       xsdType: the type name inside the XSD.
  #       description: Optionally. It has priority over type.description.
  #       minOccurs: The children must appear at least ...
  #       maxOcurrs: The children cann't appear more than ...
  types: {}

  parseFromString: (xmlString, complete) ->
    xml2js.parseString xmlString, {
      tagNameProcessors: [xml2js.processors.stripPrefix] # Strip nm prefix
      }, (err, result) =>
        @parse(result, complete)


  ## Parrse the XSD file. Prepare types and children.
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


  ## Remove new line chars and trim spaces.
  normalizeString: (str) ->
    str.replace(/[\n\r]/, '').trim() if str


  ## Get documentation string from node
  getDocumentation: (node) ->
    @normalizeString(node.annotation?[0].documentation[0]._ ?
      node.annotation?[0].documentation[0])


  ## Parse a ComplexType node and children.
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
      description: @getDocumentation node
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
      description: @getDocumentation node


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
