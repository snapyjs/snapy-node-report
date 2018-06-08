{printStd} = require "./printError"
explore = require "./explorer"

module.exports = ({run,cache,report,position,status,cancel, chalk,ask,Promise}) =>
  output = []
  done = failed = hasErrors = 0
  run.hookIn position.init, => 
    output = []
    done = failed = hasErrors = 0
    
  report.hookIn (obj) => 
    return done++ if obj.success == true
    output.push obj
    hasErrors += obj.stderr?
    failed += obj.snapLine?
    
    

  {printQuestion, closeQuestionInterface} = require("./printQuestion")(status,Promise, cancel)
  ask.hookIn printQuestion
  run.hookIn position.end, closeQuestionInterface

  userSelected =
    files: []
    errors: []

  run.hookIn position.end, ({changedChunks,cachedChunks,stats}, {readConfig,isCanceled}) =>
    unless isCanceled
      if done == stats.due.snaps and not hasErrors
        process.exitCode = 0
        status chalk.green("All #{stats.total.snaps} snap(s) out of #{stats.total.tests} test(s) are valid"), "succeed"
        return
      else 
        process.exitCode = 1
        uncalled = stats.due.snaps-done-failed
        unchanged = stats.total.snaps-stats.due.snaps
        errorMsg = ""
        if hasErrors
          errorMsg += chalk.bold("(#{hasErrors} errors) ")
        errorMsg += "#{done} valid, #{failed} invalid"
        if uncalled
          errorMsg += ", #{uncalled} not evaluated"
        if unchanged
          errorMsg += ", #{unchanged} skipped (unchanged)"
        errorMsg += " snaps"
        
        status chalk.red(errorMsg), "fail"
        output = output.sort (o1,o2) => 
          if o1.origin < o2.origin
            return -1
          else if o1.origin > o2.origin
            return 1
          return 0
        if not process.stdout.isTTY 
          for out in output
            printStd(out) if out.stderr or out.diff
        else if output.length > 0
          await explore(cache, output, Promise, cancel, readConfig.watch)