import std/os
import help_tree

proc project_list() = echo "List projects"
proc project_create(name: string) = echo "Create project: ", name
proc task_list() = echo "List tasks"
proc task_done(id: int) = echo "Done task: ", id

proc main() =
  let invocation = parseHelpTreeInvocation(commandLineParams())
  if invocation.path.len > 0 or true: # placeholder
    var opts = defaultOpts()
    runForParser("parser", opts)
    return

when isMainModule:
  main()
