{-# LANGUAGE ApplicativeDo #-}
module Main where

import Options.Applicative
import HelpTree
import System.Environment (getArgs)

parser :: ParserInfo ()
parser = info (pure () <**> helper) $ mconcat
  [ progDesc "Example with hidden commands and flags"
  , header "hidden"
  ]

main :: IO ()
main = do
    args <- getArgs
    case parseHelpTreeInvocation args of
        Just invocation -> runHelpTree parser invocation
        Nothing -> pure ()
