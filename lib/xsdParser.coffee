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
  #     description: Optionally. Not sure where it will fit.
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
    # Go to root node
    xml = xml.schema

    # Process the root node (Element type). Like a Complex type
    # But the name is in the element instead of complexType tag.
    xml.element[0].complexType[0].$ = { name: xml.element[0].$.name }
    rootType = @parseComplexType xml.element[0].complexType[0]
    rootType.type = 'class'
    rootType.rightLabel = 'Root'

    # Process all ComplexTypes
    @parseComplexType node for node in xml.complexType

    # TODO: Process all SimpleType
    # TODO: Process all AttributeGroup
    # TODO: Process all Group

    # Post parse the nodes and resolve links.
    @postParsing()

    console.log @types
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
      xsdTypeName: name
      xsdAttributes: []
      xsdChildrenMode: ''
      xsdChildren: []

      # Autocomplete params
      text: ''  # Set later
      description: @getDocumentation node
      type: 'tag'
      rightLabel: 'Tag'

    # Get the node that contains the children.
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
    else if node.complexContent?[0].extension
      type.xsdChildrenMode = 'extension'
      type.xsdChildren = node.complexContent[0].extension[0]

    # The children are in groups of type: element, sequence or choice.
    if childrenNode
      type.xsdChildren =
        (@parseChildrenGroups childrenNode.element, 'element')
        .concat((@parseChildrenGroups childrenNode.choice, 'choice'))
        .concat((@parseChildrenGroups childrenNode.sequence, 'sequence'))

    # TODO: Parse attributes
    # TODO: Create snippet from attributes.

    @types[name] = type
    return type


  ## Parse the group of children nodes.
  parseChildrenGroups: (groupNodes, mode) ->
    if not groupNodes
      return []

    # For each element/sequence/choice node, create a group object.
    groups = []
    for groupNode in groupNodes
      groups.push {
        childType: mode
        description: @getDocumentation groupNode
        minOccurs: groupNode.$?.minOccurs ? 0
        maxOccurs: groupNode.$?.maxOccurs ? 'unbounded'

        # We don't support more recursive levels -> check only for elements
        # If the mode is element, the elements is itself.
        elements: if mode == 'element' then [].concat @parseChild groupNode else
          (@parseChild childNode for childNode in (groupNode.element ? []))
      }
    return groups


  ## Parse a child node.
  parseChild: (node) ->
    child =
      tagName: node.$.name
      xsdType: node.$.type
      minOccurs: node.$.minOccurs ? 0
      maxOccurs: node.$.maxOccurs ? 'unbounded'
      description: @getDocumentation node


  ## This takes place after all nodes have been parse. Allow resolve links.
  postParsing: ->
    # Post process all nodes
    for name, type of @types

      # If the children type is extension, resolve the link.
      if type.xsdChildrenMode == 'extension'
        extensionType = type.xsdChildren

        # Copy fields from base
        linkType = @types[extensionType.$.base]
        type.xsdTypeName = linkType.xsdTypeName
        type.xsdChildrenMode = linkType.xsdChildrenMode
        type.xsdChildren = linkType.xsdChildren
        type.description ?= linkType.description
        type.type = linkType.type
        type.rightLabel = linkType.rightLabel

        # TODO: Add extensions (e.g.: attributes)
