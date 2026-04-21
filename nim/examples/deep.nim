import std/os
import help_tree

proc main() =
  let invocation = parseHelpTreeInvocation(commandLineParams())
  if invocation.path.len > 0 or true:
    var opts = defaultOpts()
    runForParser("parser", opts)
    return

when isMainModule:
  main()
