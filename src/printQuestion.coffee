chalk = require "chalk"
readline = require "readline"
{clearLines, getSource, shortenPath} = require "./helper"

rl = null
askQueue = null
    
module.exports = (status, Promise) =>
  closeQuestionInterface: => rl?.close()
  printQuestion: (obj) =>
    unless rl?
      unless process.stdin.isTTY
        throw new Error "Questions have to be asked, but no TTY detected."
      rl = readline.createInterface
        input: process.stdin
        output: process.stdout
      askQueue = Promise.resolve()
    
    askQueue = askQueue.then => new Promise (resolve, reject) =>
      status null,"stop"
      q = """

        #{chalk.bold("SNAPSHOT")}

        #{chalk.cyan("description")}:
        #{obj.description}

        #{chalk.cyan("call")} (#{shortenPath(obj.file, false)}:#{obj.snapLine}) 
        #{getSource(obj,"snap",null,"snap").join("\n")}

        #{chalk.cyan("state")}:
        #{obj.question}

        #{chalk.inverse("Is the state correct? (Y/n)")}
      """
      rl.question q, (answer) =>
        lines = q.split("\n").length
        clearLines(lines)
        status null,"start"       
        obj.correct = answer != "n" and answer != "N"
        resolve()