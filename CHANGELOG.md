## 0.11.0
Special thanks to @applesauce49 and @fizzyduck

* Implement support for 302 redirection while downloading XSD file (#55 by @fizzyduck)
* Fix bugs #36 and #54 because memberType should be optional (#54 by @applesauce49)

## 0.10.1
Special thanks to @ph777

* Add documentation of enum elements (#52 by @ph777)
* Support lang attribute in documentation (#51 by @ph777)

## 0.10.0
Special thanks to @akukuq and @ph777!

* Ignore CDATA sections when parsing XMLs (#29 by @akukuq).
* Fix multiple groups in complex type (#44 by @ph777).
* Fix xsd:extension to extend the base type with its elements (#46 by @ph777).
* Add support extension of simpleType (#47 by @ph777).
* Add support for list type (#48 by @ph777)
* Bump dependencies

## 0.9.4
* Fix XSD Windows paths starting with C:/

## 0.9.3
* Fix regex for schema location when there were attributes adjacent (#27 by @PRGfx)

## 0.9.2
* Fix #12 - XSD paths starting with file:/// weren't load.
* Additional fix for #13 - Root elements with built-in types.

## 0.9.1
* Add robustness for corner cases of reading XSD files.
* Fix #17 - Corner case where the XML schema is empty.
* Fix #13 - Root elements without type.

## 0.9.0
* Fix #23 - XPath when cursor is inside tag name.
* Fix #26 - Error trying to dispose the status bar.
* Add keymap to copy the current XPath into the clipboard.
* Fix tag value completion for fields with dots.
* Read XSD if starts with schemaLocation (namespaces aren't supported yet).

## 0.8.3
* Fix #15 - Don't force xmlns to "xs".

## 0.8.2
* Fix crash when there are tags without the name attribute.
* Fix crash when the documentation tag is empty.
* Support attribute types defined inside the node.

## 0.8.1
* Fix error detecting tag values as attributes.
* Decrease load time from ~150 ms to less than 5 ms.

## 0.8.0
* Add automatically required attributes when completing a tag.
* New configuration to add automatically the closing tag too.
* Parse XSD union SimpleType restriction.
* Autocomplete attribute values.
* Fix not autocompleting attributes for empty tags.
* Ignore prohibited attributes.

## 0.7.6
* Only parse XSD documents that follows the W3C standard.
* Show autocompletation only for XML that asks validation.
* Fix elements with a self-definition with first element "annotation".
* Fix several bugs assuming some tags were present.
* Fix using root elements as root child.

## 0.7.5
* Merge attributes from extension types.
* Throw errors to console to not annoy the user.
* Prevent error from invalid XPaths.
* Support XSD AttributeGroups.

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
