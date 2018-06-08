keypress = require "keypress"

readline = require "readline"

{shortenPath, clearLines} = require "./helper"

chalk = require "chalk"

{stdToOutput} = require "./printError"
stdout = process.stdout

lastOutputLength = 0
clearLastOutput = (plus=0) =>
  clearLines(lastOutputLength+plus) if lastOutputLength > 0
  lastOutputLength = 0

getPrefix = (selected) => if selected then chalk.cyan("-> ") else "   "

getChoices = (arr, cursor, question) =>
  choices = arr.map((el, i) => getPrefix((not cursor? and i==0) or cursor == el[0])+ el[1])
  choices.unshift("")
  if question
    choices.unshift(chalk.bold(question)) 
    choices.unshift("")
  return choices

getChoice = (arr, cursor, i=0) => 
  index = 0 unless ~(index = arr.findIndex((el) => cursor == el[0])) 
  return arr[(index+i)%%arr.length]?[0]

module.exports = (cache, output, Promise, cancel, isWatch) => new Promise (resolve) =>

  usage = (add = "") =>  
    str = "use arrows or W,A,S,D to navigate"
    str += ", Q to exit" unless isWatch
    chalk.inverse(str+add)

  outputAction = (action) =>
    clearLastOutput()
    arr = action.output()
    arr.push ""
    arr.push usage(action.usage)
    charsPerLine = stdout.columns
    lastOutputLength = arr.reduce ((acc, str) => 
      acc + Math.max(str.split("\n").length,Math.ceil(str.length / charsPerLine))
      ),0
    console.log arr.join("\n")

  {value:selection} = await cache.get key:"selection"
  tests = {}
  output.forEach (failedTest) =>
    if failedTest.diff? or failedTest.stderr? or failedTest.stdout?
      failedTest.testId = testId = shortenPath(failedTest.origin,false)
      tests[testId] = failedTest
  
  testToStatesString = (test) =>
    states = test.states = []
    states.push ["stderr",chalk.bgRed("error")] if test.stderr?
    states.push ["invalid",chalk.red("invalid snapshot")] if test.diff?
    states.push ["stdout",chalk.cyan("output")] if test.stdout?
    return  shortenPath(test.testId) + " (#{states.map((state) => state[1]).join(", ")})" 

  preparedTests = Object.keys(tests).sort().map (testId) =>
    return [testId, testToStatesString(tests[testId])]
  cursor = null
  selectedTest = null
  memory = {}
  setSelection = (i, val) => selection[i] = val; cursor = memory[val]
  removeSelection = (i) => 
    memory[selection[i]] = cursor
    cursor = selection[i]
    selection[i] = null
  typeMapping =
    moveCursor: (i) =>
      if selectedTest.states.length == 1
        # change test
        mapping.test.select getChoice preparedTests, selection[0], i
      else
        # change type
        mapping.type.select getChoice selectedTest.states, selection[1], i
    select: =>
    unselect: =>
      removeSelection 1
      if selectedTest.states.length == 1
        removeSelection 0 
        changeType("test")
      else
        changeType("type")
  mapping =
    test:
      output: => getChoices preparedTests, cursor, "Select a position to explore.."
      moveCursor: (i) => 
        cursor = getChoice preparedTests, cursor, i
        outputAction action
      select: (c) =>
        setSelection 0, test = getChoice preparedTests, c or cursor
        selectedTest = tests[test]
        if selectedTest.states.length == 1
          setSelection 1, state = selectedTest.states[0][0]
          changeType(state)
        else
          changeType("type")
      unselect: =>
    type:
      output: => getChoices selectedTest.states, cursor, "Select a type to explore.."
      moveCursor: (i) => 
        cursor = getChoice selectedTest.states, cursor, i
        outputAction action
      select: (c) =>
        setSelection 1, type = getChoice selectedTest.states, c or cursor 
        changeType(type)
      unselect: =>
        removeSelection 0
        changeType("test")
    stderr: Object.assign {
        output: => stdToOutput selectedTest, "stderr", ["", chalk.bold("ERROR")]
      }, typeMapping 
    invalid: Object.assign {
        usage: ", E to discard snapshot"
        output: => stdToOutput selectedTest, "diff", ["", chalk.bold("INVALID SNAPSHOT")]
      }, typeMapping 
    stdout: Object.assign {
        output: => stdToOutput selectedTest, "stdout", ["", chalk.bold("OUTPUT")]
      }, typeMapping 

  action = null
  type = null
  changeType = (newType) => 
    action = mapping[newType]
    type = newType
    outputAction action
    
  stdin = process.stdin
  stdout.write('\u001b[?25l')
  keypress(stdin)
  finished = false
  finish = (overview) =>
    unless finished
      finished = true
      stdin.pause()
      clearLastOutput()
      await cache.set key: "selection", value: selection
      if overview
        console.log chalk.bold "Overview:"
        for val in preparedTests
          console.log "  "+val[1]
      resolve()
  cancel.hookIn => finish(false)
  stdin.on "keypress", (ch, key) =>
    if key?
      if ((key.ctrl && key.name == "c") or (not isWatch and ((key.name == "q") or key.name == "escape")))
        await finish(true)
        process.exit(0) if isWatch
      else if key.name == "return" or key.name == "d" or key.name == "right"
        action.select()
      else if key.name == "w" or key.name == "up"
        action.moveCursor(-1)
      else if key.name == "s" or key.name == "down"
        action.moveCursor(1)
      else if key.name == "a" or key.name == "left"
        action.unselect()
      else if key.name == "e"
        if selectedTest and selection[1] == "invalid"
          await cache.discard selectedTest
          prepedTest = preparedTests.findIndex (el) => el[0] == selectedTest.testId
          if selectedTest.states.length == 1
            delete tests[selection[0]]
            preparedTests.splice(prepedTest, 1)
            if Object.keys(tests).length == 0
              finish(false)
            else
              changeType("test")
          else
            preparedTests[prepedTest][1] = testToStatesString(selectedTest)
            tmp.splice (tmp = selectedTest.states).indexOf(selection[1]), 1
            if (tmp.length == 1 and state = tmp[0][0])
              changeType(state)
            else
              changeType("type")

  stdin.setRawMode(true)
  stdin.resume()
  
  selection ?= []
  if (test = selection[0])? and (selectedTest = tests[test])?
    if ((state = selection[1])? and ~(getChoice selectedTest.states, state)) or    
        (selectedTest.states.length == 1 and state = selectedTest.states[0][0])
      changeType(state)
    else
      changeType("type")
      selection[1] = null
  else if (tmp = Object.keys(tests)).length == 1
    selectedTest = tests[tmp[0]]
    if selectedTest.states.length == 1 and state = selectedTest.states[0][0]
      changeType(state)
    else
      changeType("type")
  else
    changeType("test")

