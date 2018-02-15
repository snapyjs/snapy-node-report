readline = require "readline"

abbreviate = require "abbreviate"

path = require "path"

chalk = require "chalk"

emphasize = require "emphasize"

cwd = process.cwd()


module.exports = 
  shortenPath: (str, abbr = true) => 
    if str?
      len = str.length
      str = str.replace(cwd,".")
      if abbr and len == str.length 
        splitted = str.split(path.sep)
        len = splitted.length
        if len > 2
          for str2,i in splitted
            splitted[i] = abbreviate(str2,{}) if i < len-2
        str = splitted.join(path.sep)
    return str
  clearLines: (count=1) =>
    readline.moveCursor(process.stdout,0,-count)
    readline.clearScreenDown(process.stdout)
  getIndent: (str) => str.match(/^(\s+)/g)?[0] or ""

  getSource: (o, type, highlightLine, highlightWord) =>
    return [] unless (source = o[type+"Source"])?
    line = +o[type+"Line"]
    source = emphasize.highlightAuto(source).value
    if highlightWord?
      source = source.replace(new RegExp(highlightWord, "g"),chalk.blue(highlightWord))
    highlightLine = +highlightLine
    index = null
    return source.split("\n").map (str,i) =>
      realLine = line+i
      if highlightLine == realLine
        index = i
        chalk.bgRed(">> "+realLine)+" "+str
      else
        chalk.grey(realLine)+"    "+str