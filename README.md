# Autocomplete XML Atom Package
**Note: This is an alpha version. It is not fully implemented.**

XML tag autocompletion for Atom text editor!

![Demo](https://raw.githubusercontent.com/pleonex/atom-autocomplete-xml/master/demo.gif)

# Features
* Download and parse XSD files.
* Show autocompletation for tags with documentation if available.

# Code structure
The package code is inside the *lib* folder.

* *lib*
    * **main.coffee**: Main package file. It handles package things like calling the provider and settings.
    * **provider.coffee**: Detects the type of suggestion needed (e.g.: tag, attribute, ...) and ask for suggestions of that type. It handles everything related with the editor.
    * **xsd.coffee**: Manage the XSD types. Create suggestions. It handles suggestion creation.
    * **xsdParser.coffee**: Download and parse a XSD file and build the types. It handles XSD parsing.
