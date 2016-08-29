# Autocomplete XML Atom Package

![Downloads](https://img.shields.io/apm/dm/autocomplete-xml.svg)
![Version](https://img.shields.io/apm/v/autocomplete-xml.svg)
![License](https://img.shields.io/apm/l/autocomplete-xml.svg)
![Dependencies](https://david-dm.org/pleonex/atom-autocomplete-xml.svg)


XML tag autocompletion for Atom text editor!

![Demo](https://raw.githubusercontent.com/pleonex/atom-autocomplete-xml/master/demo.gif)

**NOTE:** The autocompletation feature is only available when:
* The XSD file follows the W3C standard. That is, the XSD root element must contain the attribute: `xmlns:xs="http://www.w3.org/2001/XMLSchema"`.
* The XML file to autocomplete ask for validation. That is, the root element must contain the attribute: `xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"`.

# Features
* Read XSD files from HTTP, HTTPS or local URI.
* Show autocompletion for tags and attributes with documentation if available.

# Code structure
The package code is inside the *lib* folder.

* *lib*
    * **main.coffee**: Main package file. It handles package things like calling the provider and settings.
    * **provider.coffee**: Detects the type of suggestion needed (e.g.: tag, attribute, ...) and ask for suggestions of that type. It handles everything related with the editor.
    * **xsd.coffee**: Manage the XSD types. Create suggestions. It handles suggestion creation.
    * **xsdParser.coffee**: Download and parse a XSD file and build the types. It handles XSD parsing.
    * **xpath-statusbar-view.coffee**: Show the current XPath in the StatusBar.
