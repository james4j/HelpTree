{-# LANGUAGE ApplicativeDo #-}
module Main where

import HelpTree
import System.Directory (doesFileExist)
import System.Environment (getArgs)

deepTree :: TreeCommand
deepTree = TreeCommand
  { cmdName = "deep"
  , cmdDescription = "A deeply nested CLI example (3 levels)"
  , cmdOptions = discoveryOptions ++ [verboseOption]
  , cmdArguments = []
  , cmdSubcommands = [server, client]
  , cmdHidden = False
  }
  where
    server = TreeCommand
      { cmdName = "server"
      , cmdDescription = "Server management"
      , cmdOptions = [verboseOption]
      , cmdArguments = []
      , cmdSubcommands = [config, db]
      , cmdHidden = False
      }
    config = TreeCommand
      { cmdName = "config"
      , cmdDescription = "Configuration commands"
      , cmdOptions = [verboseOption]
      , cmdArguments = []
      , cmdSubcommands =
          [ TreeCommand "get" "Get a config value" [verboseOption] [ TreeArgument "KEY" "Config key" True False ] [] False
          , TreeCommand "set" "Set a config value" [verboseOption] [ TreeArgument "KEY" "Config key" True False, TreeArgument "VALUE" "Config value" True False ] [] False
          , TreeCommand "reload" "Reload configuration" [verboseOption] [] [] False
          ]
      , cmdHidden = False
      }
    db = TreeCommand
      { cmdName = "db"
      , cmdDescription = "Database commands"
      , cmdOptions = []
      , cmdArguments = []
      , cmdSubcommands =
          [ TreeCommand "migrate" "Run migrations" [] [] [] False
          , TreeCommand "seed" "Seed the database" [] [] [] False
          , TreeCommand "backup" "Backup the database" [] [] [] False
          ]
      , cmdHidden = False
      }
    client = TreeCommand
      { cmdName = "client"
      , cmdDescription = "Client operations"
      , cmdOptions = [verboseOption]
      , cmdArguments = []
      , cmdSubcommands = [auth, request]
      , cmdHidden = False
      }
    auth = TreeCommand
      { cmdName = "auth"
      , cmdDescription = "Authentication commands"
      , cmdOptions = []
      , cmdArguments = []
      , cmdSubcommands =
          [ TreeCommand "login" "Log in" [] [] [] False
          , TreeCommand "logout" "Log out" [] [] [] False
          , TreeCommand "whoami" "Show current user" [] [] [] False
          ]
      , cmdHidden = False
      }
    request = TreeCommand
      { cmdName = "request"
      , cmdDescription = "HTTP request commands"
      , cmdOptions = [verboseOption]
      , cmdArguments = []
      , cmdSubcommands =
          [ TreeCommand "get" "Send a GET request" [verboseOption] [ TreeArgument "PATH" "Request path" True False ] [] False
          , TreeCommand "post" "Send a POST request" [verboseOption] [ TreeArgument "PATH" "Request path" True False ] [] False
          ]
      , cmdHidden = False
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
            runHelpTree deepTree (invocation { invocationOpts = opts' })
        Nothing -> putStrLn "Run with --help-tree to see the command tree."
