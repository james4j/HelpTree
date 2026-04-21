{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module HelpTree
  ( HelpTreeOpts(..)
  , HelpTreeInvocation(..)
  , HelpTreeTheme(..)
  , TextTokenTheme(..)
  , TextEmphasis(..)
  , defaultOpts
  , defaultTheme
  , parseHelpTreeInvocation
  , runHelpTree
  , loadConfig
  , applyConfig
  ) where

import Data.Aeson
import qualified Data.ByteString.Lazy as BL
import Data.List (intercalate)
import Data.Maybe (fromMaybe, isNothing, mapMaybe)
import System.Console.ANSI
import System.Environment (getArgs)
import System.IO (hIsTerminalDevice, stdout)
import qualified Options.Applicative as OA

data TextEmphasis = Normal | Bold | Italic | BoldItalic
  deriving (Show, Eq)

instance FromJSON TextEmphasis where
  parseJSON = withText "TextEmphasis" $ \t -> case t of
    "normal"       -> pure Normal
    "bold"         -> pure Bold
    "italic"       -> pure Italic
    "bold_italic"  -> pure BoldItalic
    _              -> fail $ "Unknown emphasis: " ++ show t

data TextTokenTheme = TextTokenTheme
  { emphasis  :: TextEmphasis
  , colorHex  :: Maybe String
  } deriving (Show, Eq)

instance FromJSON TextTokenTheme where
  parseJSON = withObject "TextTokenTheme" $ \o -> TextTokenTheme
    <$> o .:? "emphasis" .!= Normal
    <*> o .:? "color_hex"

data HelpTreeTheme = HelpTreeTheme
  { command     :: TextTokenTheme
  , options     :: TextTokenTheme
  , description :: TextTokenTheme
  } deriving (Show, Eq)

instance FromJSON HelpTreeTheme where
  parseJSON = withObject "HelpTreeTheme" $ \o -> HelpTreeTheme
    <$> o .:? "command"     .!= TextTokenTheme Bold       (Just "#7ee7e6")
    <*> o .:? "options"     .!= TextTokenTheme Normal     Nothing
    <*> o .:? "description" .!= TextTokenTheme Italic     (Just "#90a2af")

data HelpTreeOutputFormat = Text | Json
  deriving (Show, Eq)

data HelpTreeStyle = Plain | Rich
  deriving (Show, Eq)

data HelpTreeColor = ColorAuto | ColorAlways | ColorNever
  deriving (Show, Eq)

data HelpTreeOpts = HelpTreeOpts
  { depthLimit  :: Maybe Int
  , ignoreList  :: [String]
  , treeAll     :: Bool
  , output      :: HelpTreeOutputFormat
  , style       :: HelpTreeStyle
  , color       :: HelpTreeColor
  , theme       :: HelpTreeTheme
  } deriving (Show, Eq)

data HelpTreeInvocation = HelpTreeInvocation
  { invocationOpts :: HelpTreeOpts
  , invocationPath :: [String]
  } deriving (Show, Eq)

data HelpTreeConfigFile = HelpTreeConfigFile
  { configTheme :: Maybe HelpTreeTheme
  } deriving (Show, Eq)

instance FromJSON HelpTreeConfigFile where
  parseJSON = withObject "HelpTreeConfigFile" $ \o ->
    HelpTreeConfigFile <$> o .:? "theme"

defaultTheme :: HelpTreeTheme
defaultTheme = HelpTreeTheme
  { command     = TextTokenTheme Bold       (Just "#7ee7e6")
  , options     = TextTokenTheme Normal     Nothing
  , description = TextTokenTheme Italic     (Just "#90a2af")
  }

defaultOpts :: HelpTreeOpts
defaultOpts = HelpTreeOpts
  { depthLimit  = Nothing
  , ignoreList  = []
  , treeAll     = False
  , output      = Text
  , style       = Rich
  , color       = ColorAuto
  , theme       = defaultTheme
  }

shouldUseColor :: HelpTreeOpts -> IO Bool
shouldUseColor opts = case color opts of
  ColorAlways -> return True
  ColorNever  -> return False
  ColorAuto   -> hIsTerminalDevice stdout

parseHexRGB :: String -> Maybe (Int, Int, Int)
parseHexRGB hex =
  let h = dropWhile (== '#') hex
  in if length h == 6
       then case reads ("0x" ++ take 2 h) of
              [(r, _)] -> case reads ("0x" ++ take 2 (drop 2 h)) of
                [(g, _)] -> case reads ("0x" ++ drop 4 h) of
                  [(b, _)] -> Just (r, g, b)
                  _ -> Nothing
                _ -> Nothing
              _ -> Nothing
       else Nothing

styleText :: String -> TextTokenTheme -> HelpTreeOpts -> IO String
styleText text token opts = do
  useColor <- shouldUseColor opts
  let codes = emphasisCodes (emphasis token) ++ colorCodes useColor (colorHex token)
  return $ if null codes || style opts == Plain
           then text
           else "\ESC[" ++ intercalate ";" codes ++ "m" ++ text ++ "\ESC[0m"
  where
    emphasisCodes Normal      = []
    emphasisCodes Bold        = ["1"]
    emphasisCodes Italic      = ["3"]
    emphasisCodes BoldItalic  = ["1", "3"]
    colorCodes False _        = []
    colorCodes True Nothing   = []
    colorCodes True (Just hex) = case parseHexRGB hex of
      Just (r, g, b) -> ["38;2;" ++ show r ++ ";" ++ show g ++ ";" ++ show b]
      Nothing        -> []

parseHelpTreeInvocation :: [String] -> Maybe HelpTreeInvocation
parseHelpTreeInvocation argv = go argv (HelpTreeInvocation defaultOpts [])
  where
    go [] inv | any (== "--help-tree") argv = Just inv
              | otherwise = Nothing
    go ("--help-tree":xs) inv = go xs inv
    go ("--tree-depth":x:xs) inv = go xs (inv { invocationOpts = (invocationOpts inv) { depthLimit = Just (read x) } })
    go ("-L":x:xs) inv = go xs (inv { invocationOpts = (invocationOpts inv) { depthLimit = Just (read x) } })
    go ("--tree-ignore":x:xs) inv = go xs (inv { invocationOpts = (invocationOpts inv) { ignoreList = x : ignoreList (invocationOpts inv) } })
    go ("-I":x:xs) inv = go xs (inv { invocationOpts = (invocationOpts inv) { ignoreList = x : ignoreList (invocationOpts inv) } })
    go ("--tree-all":xs) inv = go xs (inv { invocationOpts = (invocationOpts inv) { treeAll = True } })
    go ("-a":xs) inv = go xs (inv { invocationOpts = (invocationOpts inv) { treeAll = True } })
    go ("--tree-output":x:xs) inv = go xs (inv { invocationOpts = (invocationOpts inv) { output = if x == "json" then Json else Text } })
    go ("--tree-style":x:xs) inv = go xs (inv { invocationOpts = (invocationOpts inv) { style = if x == "plain" then Plain else Rich } })
    go ("--tree-color":x:xs) inv = go xs (inv { invocationOpts = (invocationOpts inv) { color = case x of "always" -> ColorAlways; "never" -> ColorNever; _ -> ColorAuto } })
    go (x:xs) inv
      | head x /= '-' = go xs (inv { invocationPath = invocationPath inv ++ [x] })
      | otherwise = go xs inv

loadConfig :: FilePath -> IO (Either String HelpTreeConfigFile)
loadConfig path = do
  contents <- BL.readFile path
  return $ eitherDecode contents

applyConfig :: HelpTreeOpts -> HelpTreeConfigFile -> HelpTreeOpts
applyConfig opts cfg = case configTheme cfg of
  Just t  -> opts { theme = t }
  Nothing -> opts

runHelpTree :: OA.ParserInfo a -> HelpTreeInvocation -> IO ()
runHelpTree parserInfo invocation = do
  let opts = invocationOpts invocation
  putStrLn =<< styleText "myapp" (command (theme opts)) opts
  putStrLn ""
  putStrLn $ "Use `myapp <COMMAND> --help` for full details on arguments and flags."
