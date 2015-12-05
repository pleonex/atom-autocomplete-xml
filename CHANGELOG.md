## 0.7.5
* Merge attributes from extension types.
* Throw errors to console to not annoy the user.

## 0.7.4
* Fix using a root type as children too.
* Missing "uuid" dependency

## 0.7.3
* Fix #6 - Parse self-contained types AND multiple roots to choose.
* Fix minor bug trying to get completion from non defined types.
* Support groups XSD types.

## 0.7.2
* Fix #5 - Support HTTPS addresses.

## 0.7.1
* Fix getting suggestion for built-in types.

## 0.7.0
* Show autocompletion for attributes.
* Show autocompletion for root node.
* Fix bugs detecting values and tags types.
* Fix bug detecting parent tag.

## 0.6.1
* Fix trying to show completion before loading XSD file.

## 0.6.0
* Improve detection of autocompletion type.
* Show autocompletion for close tags.
* Filter the completions with the current prefix.
* Fix getting garbage autocompletion attributes.

## 0.5.0
* New status bar label with current XPath.

## 0.4.2
* Fix #3 - Ignore content in XML comments.
* Ignore <?xml> tags.

## 0.4.1
* Fix #2 - Relative XSD paths from current open file.

## 0.4.0
* Read XSD files from disk.
* Fix detection of parent tag from a tag name.
* Enable filtering.

## 0.3.1
* Fix detection of parent tag.

## 0.3.0
* Autocomplete for ComplextContent child elements.
* Autocomplete for some XSD SimpleType.
* Fix some tag detection issues.

## 0.2.0
* Fix some bugs.
* Autocomplete for root children nodes.

## 0.1.0
* Get the URL of the XSD from the XML attribute.
* Download a XSD from an URL.
* Show basic autocompletation from XSD ComplexTypes.
