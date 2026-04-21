{-# LANGUAGE ApplicativeDo #-}
module Main where

import HelpTree
import System.Environment (getArgs)

basicTree :: TreeCommand
basicTree = TreeCommand
  { cmdName = "basic"
  , cmdDescription = "A basic example CLI with nested subcommands"
  , cmdOptions = discoveryOptions ++ [ TreeOption "verbose" "" "--verbose" "Verbose output" False False "" False ]
  , cmdArguments = []
  , cmdSubcommands = [project, task]
  , cmdHidden = False
  }
  where
    project = TreeCommand
      { cmdName = "project"
      , cmdDescription = "Manage projects"
      , cmdOptions = [ TreeOption "verbose" "" "--verbose" "Verbose output" False False "" False ]
      , cmdArguments = []
      , cmdSubcommands =
          [ TreeCommand "list" "List all projects" [ TreeOption "verbose" "" "--verbose" "Verbose output" False False "" False ] [] [] False
          , TreeCommand "create" "Create a new project" [ TreeOption "verbose" "" "--verbose" "Verbose output" False False "" False ] [ TreeArgument "NAME" "Project name" True False ] [] False
          ]
      , cmdHidden = False
      }
    task = TreeCommand
      { cmdName = "task"
      , cmdDescription = "Manage tasks"
      , cmdOptions = [ TreeOption "verbose" "" "--verbose" "Verbose output" False False "" False ]
      , cmdArguments = []
      , cmdSubcommands =
          [ TreeCommand "list" "List all tasks" [ TreeOption "verbose" "" "--verbose" "Verbose output" False False "" False ] [] [] False
          , TreeCommand "done" "Mark a task as done" [ TreeOption "verbose" "" "--verbose" "Verbose output" False False "" False ] [ TreeArgument "ID" "Task ID" True False ] [] False
          ]
      , cmdHidden = False
      }

main :: IO ()
main = do
    args <- getArgs
    case parseHelpTreeInvocation args of
        Just invocation -> runHelpTree basicTree invocation
        Nothing -> putStrLn "Run with --help-tree to see the command tree."
