{-# LANGUAGE ApplicativeDo #-}
module Main where

import HelpTree
import System.Directory (doesFileExist)
import System.Environment (getArgs)

hiddenTree :: TreeCommand
hiddenTree = TreeCommand
  { cmdName = "hidden"
  , cmdDescription = "An example with hidden commands and flags"
  , cmdOptions = discoveryOptions ++
      [ verboseOption
      , TreeOption "debug" "" "--debug" "Enable debug mode" False False "" True
      ]
  , cmdArguments = []
  , cmdSubcommands = [list, showCmd, admin]
  , cmdHidden = False
  }
  where
    list = TreeCommand "list" "List items" [] [] [] False
    showCmd = TreeCommand "show" "Show item details" [] [ TreeArgument "ID" "Item ID" True False ] [] False
    admin = TreeCommand
      { cmdName = "admin"
      , cmdDescription = "Administrative commands"
      , cmdOptions = []
      , cmdArguments = []
      , cmdSubcommands =
          [ TreeCommand "users" "List all users" [] [] [] False
          , TreeCommand "stats" "Show system stats" [] [] [] False
          , TreeCommand "secret" "Secret backdoor" [] [] [] False
          ]
      , cmdHidden = True
      }

main :: IO ()
main = do
    args <- getArgs
    case parseHelpTreeInvocation args of
        Just invocation -> do
            let configPath = "examples/help-tree.json"
            configExists <- doesFileExist configPath
            opts' <- if configExists
                then do
                    eConfig <- loadConfig configPath
                    case eConfig of
                        Left _ -> return (invocationOpts invocation)
                        Right config -> return (applyConfig (invocationOpts invocation) config)
                else return (invocationOpts invocation)
            runHelpTree hiddenTree (invocation { invocationOpts = opts' })
        Nothing -> putStrLn "Run with --help-tree to see the command tree."
