http = require 'http'
xml2js = require 'xml2js'

module.exports =
  complexTypes: {}

  constructor: (xsdUrl, complete) ->
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
            @parse(result, complete)

  parse: (xml, complete) ->
    console.log(xml)
    xml = xml.schema

    # TODO: Process all ComplexTypes
    @addComplexType node for node in xml.complexType

    # TODO: Process all SimpleType
    # TODO: Process all AttributeGroup
    # TODO: Process the root node (Element)
    # TODO: Process all Group
    complete()

  normalizeString: (str) ->
    str.replace(/[\n\r]/, '').trim() if str

  addComplexType: (node) ->
    name = node.$.name
    type =
      text: name
      description: @normalizeString(node.annotation?[0].documentation[0]._)
      type: 'tag'
      rightLabel: 'Tag'

    @complexTypes[name] = type

  getChildren: (name) ->
    @complexTypes[name]
