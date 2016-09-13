# This will catch:
# * Start tags: <tagName
# * End tags: </tagName
# * Auto close tags: />
startTagPattern = '<\s*[\\.\\-:_a-zA-Z0-9]+'
endTagPattern = '<\\/\s*[\\.\\-:_a-zA-Z0-9]+'
autoClosePattern = '\\/>'
startCommentPattern = '\s*<!--'
endCommentPattern = '\s*-->'
fullPattern = new RegExp("(" +
  startTagPattern + "|" + endTagPattern + "|" + autoClosePattern + "|" +
  startCommentPattern + "|" + endCommentPattern + ")", "g")
wordPattern = new RegExp('^(\\w+)')


module.exports =
  getXPathWithPrefix: (buffer, bufferPosition, prefix, maxDepth) ->
    {row, column} = bufferPosition
    column -= prefix.length
    return @getXPath(buffer, row, column, maxDepth)


  getXPathCompleteWord: (buffer, bufferPosition, maxDepth) ->
    {row, column} = bufferPosition

    # Try to get the end of the current word if any
    line = buffer.lineForRow(row).slice(column)
    wordMatch = line.match(wordPattern)
    column += wordMatch[1].length if wordMatch

    return @getXPath(buffer, row, column, maxDepth)


  getXPath: (buffer, row, column, maxDepth) ->
    # For every row, checks if it's an open, close, or autoopenclose tag and
    # update a list of all the open tags.
    xpath = []
    skipList = []
    waitingStartTag = false
    waitingStarTComment = false

    # For the first line read removing the prefix
    line = buffer.getTextInRange([[row, 0], [row, column]])

    while row >= 0 and (!maxDepth or xpath.length < maxDepth)
      row--

      # Apply the regex expression, read from right to left.
      matches = line.match(fullPattern)
      matches?.reverse()

      for match in matches ? []
        # Start comment
        if match == "<!--"
          waitingStartComment = false
        # End comment
        else if match == "-->"
          waitingStartComment = true
        # Ommit comment content
        else if waitingStartComment
          continue
        # Auto tag close
        else if match == "/>"
          waitingStartTag = true
        # End tag
        else if match[0] == "<" && match[1] == "/"
          skipList.push match.slice 2
        # This should be a start tag
        else if match[0] == "<" && waitingStartTag
          waitingStartTag = false
        else if match[0] == "<"
          tagName = match.slice 1

          # Ommit XML definition.
          if tagName == "?xml"
            continue

          idx = skipList.lastIndexOf tagName
          if idx != -1 then skipList.splice idx, 1 else xpath.push tagName

      # Get next line
      line = buffer.lineForRow(row)

    return xpath.reverse()
