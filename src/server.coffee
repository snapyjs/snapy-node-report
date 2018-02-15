{printStd} = require "./printError"
explore = require "./explorer"

module.exports = ({run,success,fail,std,cache,position,status,cancel, chalk,ask,Promise}) =>
  done = []
  failedTests = []
  output = {}
  run.hookIn position.init, => 
    done = []
    failedTests = []
  success.hookIn (obj) => done.push obj
  fail.hookIn (obj) => failedTests.push obj
  std.hookIn (obj) => output[obj.origin] = obj

  {printQuestion, closeQuestionInterface} = require("./printQuestion")(status,Promise)
  ask.hookIn printQuestion
  run.hookIn position.end, closeQuestionInterface

  userSelected =
    files: []
    errors: []

  run.hookIn position.end, ({changedChunks,cachedChunks,stats}, {readConfig,isCanceled}) =>
    unless isCanceled
      if done.length == stats.due.snaps
        process.exitCode = 0
        status chalk.green("All #{stats.total.snaps} snap(s) out of #{stats.total.tests} test(s) are valid"), "succeed"
        
        return
      else 
        process.exitCode = 1
        uncalled = stats.due.snaps-done.length-failedTests.length
        unchanged = stats.total.snaps-stats.due.snaps
        failed = "#{done.length} valid, #{failedTests.length} invalid"
        if uncalled
          failed += ", #{uncalled} not evaluated"
        if unchanged
          failed += ", #{unchanged} skipped (unchanged)"
        failed += " snaps"
        status chalk.red(failed), "fail"
        failedTests = failedTests.sort (o1,o2) =>
          if o1.file != o2.file
            if o1.file < o2.file
              return -1
            else
              return 1
          else
            return o1.line - o2.line
        if not process.stdout.isTTY 
          for error in failedTests
            printStd(error, "diff")
          for std in output
            printStd(std, "stderr")
        else if failedTests.length > 0 or Object.keys(output).length > 0
          await explore(cache, output, failedTests, Promise, cancel, readConfig.watch)