xml2js = require 'xml2js'
uuid = require 'uuid'

module.exports =
  # Expected type object from external modules.
  # type:
  #   text: The text for autocomplete. Set externally from child.tagName.
  #   displayText: Same as text but text may contain closing tags, etc...
  #   description: Documentation info. It can be empty.
  #   type: The autocomplete type.
  #   rightLabel: The autocomplete right libel. The XML type of element.
  #   leftLabel: The type of the value.
  #
  #   xsdType: The XSD type (e.g.: complex, simple, attribute).
  #   xsdTypeName: The name inside the XSD.
  #   xsdChildrenMode: The order of the children: all, sequence or choice.
  #   xsdChildren: References to other types. They are in groups.
  #     childType: The type of children nodes group: element, sequence or choice
  #     ref: Only for groups. Group name with the elements.
  #     description: Optionally. Not sure where it will fit.
  #     minOccurs: The group of children must appear at least...
  #     maxOccurs: The group of children cann't appear more than ...
  #     elements: The elements of the group (they must be elements tags).
  #       tagName: The name of the tag.
  #       xsdTypeName: the type name inside the XSD.
  #       description: Optionally. It has priority over type.description.
  #       minOccurs: The children must appear at least ...
  #       maxOcurrs: The children cann't appear more than ...
  #  xsdAttributes: The attributes of the element.
  #    name: The attribute name.
  #    type: The attribute type.
  #    description: Optional. The attribute documentation.
  #    fixed: Optional. The fixed value of the attribute.
  #    use: If the attribute must be present or not. Default: false.
  #    default: Thea attribute default value.
  types: {}
  roots: {}
  attributeGroups: {}

  parseFromString: (xmlString, complete) ->
    xml2js.parseString xmlString, {
      tagNameProcessors: [xml2js.processors.stripPrefix] # Strip nm prefix
      preserveChildrenOrder: true
      explicitChildren: true
      }, (err, result) =>
        if err then console.error err else @parse(result, complete)


  ## Parrse the XSD file. Prepare types and children.
  parse: (xml, complete) ->
    # Go to root node
    xml = xml.schema

    # Check that there is a schema
    if not xml
      return

    # Check that the schema follow the standard
    xsdStandard = xml.$["xmlns:xs"]
    if not xsdStandard or xsdStandard isnt "http://www.w3.org/2001/XMLSchema"
      console.log "The schema doesn't follow the standard."
      return

    # Process all ComplexTypes and SimpleTypes
    @parseType node for node in xml.$$

    # Process the root node (Element type).
    @parseRoot node for node in xml.element

    # Process all AttributeGroup (not regular types).
    @parseAttributeGroup node for node in (xml.attributeGroup ? [])

    # Post parse the nodes and resolve links.
    @postParsing()


  ## Parse a node type.
  parseType: (node, typeName) ->
    # Create a basic type from the common fields.
    type = @initTypeObject node, typeName

    # Parse by node type.
    nodeName = node["#name"]
    if nodeName is "simpleType"
      @parseSimpleType node, type
    else if nodeName is "complexType"
      @parseComplexType node, type
    else if nodeName is "group"
      @parseGroupType node, type


  ## Remove new line chars and trim spaces.
  normalizeString: (str) ->
    str.replace(/[\n\r]/, '').trim() if str


  ## Get documentation string from node
  getDocumentation: (node) ->
    @normalizeString(node?.annotation?[0].documentation[0]._ ?
      node?.annotation?[0].documentation[0])


  # Initialize a type object from a Simple or Complex type node.
  initTypeObject: (node, typeName) ->
    type =
      # XSD params
      xsdType: ''
      xsdTypeName: typeName ? node.$.name
      xsdAttributes: []
      xsdChildrenMode: ''
      xsdChildren: []

      # Autocomplete params
      text: ''  # Set later
      displayText: ''  # Set later
      description: @getDocumentation node
      type: 'tag'
      rightLabel: 'Tag'


  ## Parse a SimpleType.
  parseSimpleType: (node, type) ->
    type.xsdType = 'simple'

    # Get the node that contains the children
    # TODO: Support list children.
    # TODO: Support union children.
    # TODO: Support more restriction types.
    if node.restriction?[0].enumeration
      type.xsdChildrenMode = 'restriction'
      childrenNode = node.restriction[0]
      type.leftLabel = childrenNode.$.base

      group =
        childType: 'choice'
        description: ''
        minOccurs: 0
        maxOccurs: 'unbounded'
        elements: []
      type.xsdChildren.push group

      for val in childrenNode.enumeration
        group.elements.push {
          tagName: val.$.value
          xsdTypeName: null
          description: ''
          minOccurs: 0
          maxOccurs: 1
        }

    @types[type.xsdTypeName] = type
    return type


  ## Parse a ComplexType node and children.
  parseComplexType: (node, type) ->
    type.xsdType = 'complex'

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
    else if node.group
      type.xsdChildrenMode = 'group'
      type.xsdChildren = node.group[0]

    # The children are in groups of type: element, sequence or choice.
    if childrenNode
      type.xsdChildren =
        (@parseChildrenGroups childrenNode.element, 'element')
        .concat((@parseChildrenGroups childrenNode.choice, 'choice'))
        .concat((@parseChildrenGroups childrenNode.sequence, 'sequence'))
        .concat((@parseChildrenGroups childrenNode.group, 'group'))

    # TODO: Create snippet from attributes.
    if node.attribute
      type.xsdAttributes = (@parseAttribute n for n in node.$$).filter Boolean

    @types[type.xsdTypeName] = type
    return type


  ## Parse the group of children nodes.
  parseChildrenGroups: (groupNodes, mode) ->
    if not groupNodes
      return []

    # For each element/sequence/choice node, create a group object.
    groups = []
    for node in groupNodes
      groups.push {
        childType: mode
        ref: node.$?.ref
        description: @getDocumentation node
        minOccurs: node.$?.minOccurs ? 0
        maxOccurs: node.$?.maxOccurs ? 'unbounded'

        # If the mode is element, the elements is itself.
        elements: if mode is 'element' then [].concat @parseElement node else
          (@parseElement childNode for childNode in (node.element ? []))
      }
    return groups


  ## Parse a child node.
  parseElement: (node) ->
    child =
      tagName: node.$.name ? node.$.ref
      xsdTypeName: node.$.type ? node.$.ref
      minOccurs: node.$.minOccurs ? 0
      maxOccurs: node.$.maxOccurs ? 'unbounded'
      description: @getDocumentation node

    # If the element type is defined inside.
    if not child.xsdTypeName and node.$$
      # Create a randome type name and parse the child.
      # Iterate to skip "annotation", etc. It should ignore all except one.
      child.xsdTypeName = uuid()
      @parseType childNode, child.xsdTypeName for childNode in node.$$

    return child

  ## Parse attributes.
  parseAttribute: (node) ->
    nodeName = node["#name"]
    if nodeName is "attribute"
      return {
        name: node.$.name
        type: node.$.type
        description: @getDocumentation node
        fixed: node.$.fixed
        use: node.$.use
        default: node.$.default
      }
    else if nodeName is "attributeGroup"
      return {ref: node.$.ref}
    else
      return null


  ## Parse a AttributeGroup node.
  parseAttributeGroup: (node) ->
    name = node.$.name
    attributes = (@parseAttribute xattr for xattr in node.$$).filter Boolean
    @attributeGroups[name] = attributes


  ## Parse a group node.
  parseGroupType: (node, type) ->
    @parseComplexType(node, type)


  ## Parse the root node.
  parseRoot: (node) ->
    # First parse the node as a element
    rootElement = @parseElement node
    rootTagName = rootElement.tagName
    rootType = @types[rootElement.xsdTypeName]

    # Now create a complex type.
    root = @initTypeObject null, rootElement.xsdTypeName
    root.description = rootElement.description ? rootType.description
    root.text = rootTagName
    root.displayText = rootTagName
    root.type = 'class'
    root.rightLabel = 'Root'
    root.xsdType = 'complex'

    # Copy the type into the root object.
    root.xsdAttributes = rootType.xsdAttributes
    root.xsdChildrenMode = rootType.xsdChildrenMode
    root.xsdChildren = rootType.xsdChildren

    @roots[rootTagName] = root
    return root


  ## This takes place after all nodes have been parse. Allow resolve links.
  postParsing: ->
    # Post process all nodes
    for name, type of @types
      # If the children type is extension, resolve the link.
      if type.xsdChildrenMode == 'extension'
        extenType = type.xsdChildren
        extenAttr = (@parseAttribute n for n in (extenType.$$ or []))
          .filter Boolean

        # Copy fields from base
        linkType = @types[extenType.$.base]
        type.xsdTypeName = linkType.xsdTypeName
        type.xsdChildrenMode = linkType.xsdChildrenMode
        type.xsdChildren = linkType.xsdChildren
        type.xsdAttributes = extenAttr.concat linkType.xsdAttributes
        type.description ?= linkType.description
        type.type = linkType.type
        type.rightLabel = linkType.rightLabel

      # If it's a group, resolve the link
      else if type.xsdChildrenMode == 'group'
        groupType = type.xsdChildren

        # Copy the children
        linkType = @types[groupType.$.ref]
        type.xsdChildren = linkType.xsdChildren
        type.xsdChildrenMode = linkType.xsdChildrenMode

      # At the moment, I think it only makes sense if it replaces all the
      # elements. Consider a group that contains a sequence of choice elements.
      # We don't support sequence->sequence(from group)->choide->elements.
      for group in type.xsdChildren
        if group.childType is 'group'
          linkType = @types[group.ref]
          type.xsdChildren = linkType.xsdChildren
          break

      # Add the attributes from the group attributes
      groups = (attr.ref for attr in type.xsdAttributes when attr.ref)
      attributes = []
      for attr in type.xsdAttributes
        if attr.ref
          attributes = attributes.concat @attributeGroups[attr.ref]
        else
          attributes.push attr
      type.xsdAttributes = attributes
