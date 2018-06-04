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
    xml2js = require 'xml2js'
    xml2js.parseString xmlString, {
      tagNameProcessors: [xml2js.processors.stripPrefix] # Strip nm prefix
      preserveChildrenOrder: true
      explicitChildren: true
      }, (err, result) =>
        if err
          console.error err
        else if not result
          console.error "Empty XSD definition"
        else
          @parse(result, complete)


  ## Parrse the XSD file. Prepare types and children.
  parse: (xml, complete) ->
    # Go to root node
    xml = xml.schema

    # Check that there is a schema
    if not xml
      return

    # Check that the schema follow the standard
    for name, value of xml.$
      if value is "http://www.w3.org/2001/XMLSchema"
        schemaFound = true

    if not schemaFound
      console.log "The schema doesn't follow the standard."
      return

    # Check if there is at least one node in the schema definition
    if not xml.$$
      console.log "The schema is empty."
      return

    # Process all ComplexTypes and SimpleTypes
    @parseType node for node in xml.$$

    # Process the root node (Element type).
    @parseRoot node for node in xml.element

    # Copy root types into types since they could be used too.
    @types[name] = value for name, value of @roots

    # Process all AttributeGroup (not regular types).
    @parseAttributeGroup node for node in (xml.attributeGroup ? [])

    # Post parse the nodes and resolve links.
    @postParsing()


  ## Parse a node type.
  parseType: (node, typeName) ->
    # Create a basic type from the common fields.
    type = @initTypeObject node, typeName
    return null if not type.xsdTypeName

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
    str?.replace?(/[\n\r]/, '').trim()


  ## Return true if built-in types
  isBuiltInType: (typeName) ->
    parts = typeName.split ':'
    # Built-in types have to be prefixed with XSD schema prefix
    if parts.length != 2
      return false
    # TODO check namespace prefix, I'm not sure how to do that
    # Check built-in type names
    return parts[1] in [
      'string',
      'boolean',
      'decimal',
      'float',
      'double',
      'duration',
      'dateTime',
      'time',
      'date',
      'gYearMonth',
      'gYear',
      'gMonthDay',
      'gDay',
      'gMonth',
      'hexBinary',
      'base64Binary',
      'anyURI',
      'QName',
      'NOTATION'
    ]


  ## Get documentation string from node
  getDocumentation: (node) ->
    @normalizeString(node?.annotation?[0].documentation[0]._ ?
      node?.annotation?[0].documentation[0])


  # Initialize a type object from a Simple or Complex type node.
  initTypeObject: (node, typeName) ->
    type =
      # XSD params
      xsdType: ''
      xsdTypeName: typeName ? node?.$?.name
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
    # TODO: Support more restriction types.
    if node.restriction?[0].enumeration
      type.xsdChildrenMode = 'restriction'
      childrenNode = node.restriction[0]
      type.leftLabel = childrenNode.$.base
    else if node.union
      type.xsdChildrenMode = 'union'
      type.leftLabel = node.union[0].$.memberTypes
    else if node.list
      type.xsdChildrenMode = 'list'
      type.leftLabel = node.list[0].$.itemType

    if childrenNode
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
    else if node.simpleContent?[0].extension
      type.xsdType = 'simple'
      type.xsdChildrenMode = 'extension'
      type.xsdChildren = node.simpleContent[0].extension[0]
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


  # Parse the simple type defined inside a node with a random UUID.
  parseAnonElements: (node) ->
    # Create a randome type name and parse the child.
    # Iterate to skip "annotation", etc. It should ignore all except one.
    randomName = require('uuid')()
    @parseType childNode, randomName for childNode in node.$$
    return randomName


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
      child.xsdTypeName = @parseAnonElements node

    return child

  ## Parse attributes.
  parseAttribute: (node) ->
    nodeName = node["#name"]
    if nodeName is "attribute" and node.$.use isnt "prohibited"
      attr =
        name: node.$.name
        type: node.$.type
        description: @getDocumentation node
        fixed: node.$.fixed
        use: node.$.use
        default: node.$.default

      # If the attribute type is defined inside.
      if not node.$.type and node.$$
        attr.type = @parseAnonElements node
      return attr
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
    root.description = rootElement.description ? rootType?.description
    root.text = rootTagName
    root.displayText = rootTagName
    root.type = 'class'
    root.rightLabel = 'Root'
    root.xsdType = 'complex'

    # Copy the type into the root object.
    if rootType
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
        if not linkType
          # Ingore link type for simple types reffering to standard simple types like xs:string, etc.
          if type.xsdType == 'simple' and @isBuiltInType(extenType.$.base)
            linkType = @initTypeObject null, type.xsdTypeName
          else
            atom.notifications.addError "can't find base type " + extenType.$.base
            continue

        # Get extending elements to merge them with linkType children
        extendingType = @initTypeObject null, "someType"
        @parseComplexType extenType, extendingType

        type.xsdTypeName = linkType.xsdTypeName
        type.xsdChildrenMode = linkType.xsdChildrenMode
        type.xsdChildren = linkType.xsdChildren.concat extendingType.xsdChildren
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

      # If it's an union, merge the single types
      else if type.xsdChildrenMode is 'union'
        unionTypes = type.leftLabel.split(' ')
        type.xsdChildrenMode = 'restriction'
        for t in unionTypes
          memberType = @types[t]
          type.xsdChildren.push memberType.xsdChildren[0] if memberType

      # If it's a list
      else if type.xsdChildrenMode == 'list'
        itemType = type.leftLabel
        if not @isBuiltInType(itemType)
          listType = @types[itemType]
          if not listType
            atom.notifications.addError "can't find item type " + itemType
            continue
          type.xsdChildren = listType.xsdChildren
          type.leftLabel = ''
        else
          type.leftLabel = 'list of '.concat(type.leftLabel)

      # Resolve all groups in type
      newChildren = []
      for group in type.xsdChildren
        if group.childType is 'group'
          linkType = @types[group.ref]
          newChildren = newChildren.concat(linkType.xsdChildren)
        else
          newChildren = newChildren.concat([group])
      type.xsdChildren = newChildren

      # Add the attributes from the group attributes
      groups = (attr.ref for attr in type.xsdAttributes when attr.ref)
      attributes = []
      for attr in type.xsdAttributes
        if attr.ref
          attributes = attributes.concat @attributeGroups[attr.ref]
        else
          attributes.push attr
      type.xsdAttributes = attributes
