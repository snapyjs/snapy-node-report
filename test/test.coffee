{test, ask} = require "snapy"

console.log "outside of test1"

test (snap) =>
  # test1
  # test11
  snap plain: true, promise: ask {
    key:"someKey"
    question: "Press Enter"
    description: "Press Enter"
    snapLine: 8
    snapSource: "console.log('Press Enter')\nconsole.log('do it!')"
    file: "./test/test.coffee"
  }


test (snap) =>
  # test2
  # test22
  console.log "within test2"
  #snap obj: Date.now()
  # test23
  snap obj: "test"