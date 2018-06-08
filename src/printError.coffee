chalk = require "chalk"


{clearLines,getIndent,shortenPath,getSource} = require "./helper"

prependStr = (prep, str) =>
  arr = str.split("\n")
  return prep+arr.join("\n"+prep)

diffToArray = (diff) =>
  arr = []
  if diff
    for d in diff
      if d.added
        arr.push chalk.blue(prependStr("+ ",d.value.trimRight()))
      else if d.removed
        arr.push chalk.red(prependStr("- ",d.value.trimRight()))
      else if d.count > 3
        val = d.value.split("\n")
        first = val[0]
        second = val[1]
        len = val.length
        indent = getIndent(second)
        arr.push "  "+first
        isBlock = getIndent(first).length < indent.length
        if d.count == 4 and isBlock
          arr.push "  "+second
        else
          arr.push "  #{indent}…"
        arr.push "  "+val[len-2] if isBlock
        arr.push "  "+val[len-1]
      else
        arr.push "  "+d.value.trimRight()
  return arr

getType = ({diff,stderr,stdout}) =>
  if diff?
    return "diff"
  else if stderr
    return "stderr"
  else if stdout
    return "stdout"

getArr = (o, type) =>
  if type == "diff"
    return diffToArray(o[type])
  else
    return o[type]



newLine = ""
sep = ":"
space = " "

concat = (arr1,arrs...) =>
  for arr in arrs
    Array.prototype.push.apply(arr1, arr)
  return arr1

stdToOutput = (error, type , header = []) =>
    type ?= getType(error)
    content = getArr(error, type)
    source = getSource(error, "test", error.snapLine, if error.snapLine then "snap" else "console.log")
    if source.length > 0
      source = concat [
        newLine
        chalk.cyan("source") + ": (" + shortenPath(error.origin, false)+")"
        ], source, [
          newLine
          ]
    else
      source = [
        newLine
        chalk.cyan("source") + sep + space + shortenPath(error.origin, false)
        newLine
      ]
    return concat header, source, [
        chalk.cyan(type) + sep
      ], content

module.exports =
  stdToOutput: stdToOutput
  printStd: (std) => 
    out = stdToOutput(std)
    console.log out.join("\n") if out.length > 0
    