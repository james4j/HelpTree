{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module HelpTree
  ( HelpTreeOpts(..)
  , HelpTreeInvocation(..)
  , HelpTreeTheme(..)
  , TextTokenTheme(..)
  , TextEmphasis(..)
  , TreeCommand(..)
  , TreeOption(..)
  , TreeArgument(..)
  , defaultOpts
  , defaultTheme
  , discoveryOptions
  , parseHelpTreeInvocation
  , runHelpTree
  , loadConfig
  , applyConfig
  , verboseOption
  ) where

import Data.Aeson
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Lazy.Char8 as BLC
import Data.List (intercalate)
import Data.Maybe (mapMaybe)
import System.IO (hIsTerminalDevice, hSetEncoding, stdout, utf8)
import Text.Read (readMaybe)

treeAlignWidth :: Int
treeAlignWidth = 28

minDots :: Int
minDots = 4

data TextEmphasis = Normal | Bold | Italic | BoldItalic
  deriving (Show, Eq)

instance FromJSON TextEmphasis where
  parseJSON = withText "TextEmphasis" $ \t -> case t of
    "normal"       -> pure Normal
    "bold"         -> pure Bold
    "italic"       -> pure Italic
    "bold_italic"  -> pure BoldItalic
    _              -> fail $ "Unknown emphasis: " ++ show t

instance ToJSON TextEmphasis where
  toJSON Normal = String "normal"
  toJSON Bold = String "bold"
  toJSON Italic = String "italic"
  toJSON BoldItalic = String "bold_italic"

data TextTokenTheme = TextTokenTheme
  { emphasis  :: TextEmphasis
  , colorHex  :: Maybe String
  } deriving (Show, Eq)

instance FromJSON TextTokenTheme where
  parseJSON = withObject "TextTokenTheme" $ \o -> TextTokenTheme
    <$> o .:? "emphasis" .!= Normal
    <*> o .:? "color_hex"

instance ToJSON TextTokenTheme where
  toJSON (TextTokenTheme e c) = object $ ["emphasis" .= e] ++ ["color_hex" .= c | isJust c]
    where isJust (Just _) = True
          isJust Nothing  = False

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

instance ToJSON HelpTreeTheme where
  toJSON (HelpTreeTheme c o d) = object ["command" .= c, "options" .= o, "description" .= d]

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

instance ToJSON HelpTreeConfigFile where
  toJSON (HelpTreeConfigFile t) = object ["theme" .= t]

data TreeOption = TreeOption
  { optName        :: String
  , optShort       :: String
  , optLong        :: String
  , optDescription :: String
  , optRequired    :: Bool
  , optTakesValue  :: Bool
  , optDefaultVal  :: String
  , optHidden      :: Bool
  } deriving (Show, Eq)

data TreeArgument = TreeArgument
  { argName        :: String
  , argDescription :: String
  , argRequired    :: Bool
  , argHidden      :: Bool
  } deriving (Show, Eq)

data TreeCommand = TreeCommand
  { cmdName        :: String
  , cmdDescription :: String
  , cmdOptions     :: [TreeOption]
  , cmdArguments   :: [TreeArgument]
  , cmdSubcommands :: [TreeCommand]
  , cmdHidden      :: Bool
  } deriving (Show, Eq)

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

discoveryOptions :: [TreeOption]
discoveryOptions =
  [ TreeOption "help-tree" "" "--help-tree" "Print a recursive command map derived from framework metadata" False False "" False
  , TreeOption "tree-depth" "-L" "--tree-depth" "Limit --help-tree recursion depth (Unix tree -L style)" False True "" False
  , TreeOption "tree-ignore" "-I" "--tree-ignore" "Exclude subtrees/commands from --help-tree output (repeatable)" False True "" False
  , TreeOption "tree-all" "-a" "--tree-all" "Include hidden subcommands in --help-tree output" False False "" False
  , TreeOption "tree-output" "" "--tree-output" "Output format (text or json)" False True "" False
  , TreeOption "tree-style" "" "--tree-style" "Tree text styling mode (rich or plain)" False True "" False
  , TreeOption "tree-color" "" "--tree-color" "Tree color mode (auto, always, never)" False True "" False
  ]

verboseOption :: TreeOption
verboseOption = TreeOption "verbose" "" "--verbose" "Verbose output" False False "" False

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
    go ("--tree-depth":x:xs) inv = go xs (inv { invocationOpts = (invocationOpts inv) { depthLimit = readMaybe x } })
    go ("-L":x:xs) inv = go xs (inv { invocationOpts = (invocationOpts inv) { depthLimit = readMaybe x } })
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

-- ---------------------------------------------------------------------------
-- Tree rendering
-- ---------------------------------------------------------------------------

shouldSkipOption :: TreeOption -> Bool -> Bool
shouldSkipOption opt treeAll
  | treeAll   = False
  | optHidden opt = True
  | optName opt == "help" || optName opt == "version" = True
  | otherwise = False

shouldSkipArgument :: TreeArgument -> Bool -> Bool
shouldSkipArgument arg treeAll
  | treeAll   = False
  | argHidden arg = True
  | otherwise = False

shouldSkipCommand :: TreeCommand -> HelpTreeOpts -> Bool
shouldSkipCommand cmd opts
  | cmdName cmd == "help" = True
  | cmdName cmd `elem` ignoreList opts = True
  | not (treeAll opts) && cmdHidden cmd = True
  | otherwise = False

commandSignature :: TreeCommand -> Bool -> (String, String)
commandSignature cmd treeAll =
  let suffix = concatMap argSuffix (cmdArguments cmd)
      argSuffix arg
        | shouldSkipArgument arg treeAll = ""
        | argRequired arg = " <" ++ argName arg ++ ">"
        | otherwise = " [" ++ argName arg ++ "]"
      hasFlags = any (\opt -> not (shouldSkipOption opt treeAll)) (cmdOptions cmd)
      flagsSuffix = if hasFlags then " [flags]" else ""
  in (cmdName cmd, suffix ++ flagsSuffix)

renderTextLines :: TreeCommand -> String -> Int -> HelpTreeOpts -> IO [String]
renderTextLines cmd prefix depth opts = do
  let items = filter (\sub -> not (shouldSkipCommand sub opts)) (cmdSubcommands cmd)
  if null items
    then return []
    else fmap concat $ mapM (renderItem items) (zip [0..] items)
  where
    atLimit = case depthLimit opts of
                Just dl -> depth >= dl
                Nothing -> False
    renderItem allItems (idx, sub) = do
      let isLast = idx == length allItems - 1
          branch = if isLast then "└── " else "├── "
          (name, suffix) = commandSignature sub (treeAll opts)
          signature = name ++ suffix
          about = cmdDescription sub
      nameStyled <- styleText name (command (theme opts)) opts
      suffixStyled <- styleText suffix (HelpTree.options (theme opts)) opts
      let sigStyled = nameStyled ++ suffixStyled
      line <- if not (null about)
                then do
                  let dotsLen = max minDots (treeAlignWidth - length signature)
                      dots = replicate dotsLen '.'
                  aboutStyled <- styleText about (description (theme opts)) opts
                  return $ prefix ++ branch ++ sigStyled ++ " " ++ dots ++ " " ++ aboutStyled
                else return $ prefix ++ branch ++ sigStyled
      let extension = if isLast then "    " else "│   "
      childLines <- if atLimit then return [] else renderTextLines sub (prefix ++ extension) (depth + 1) opts
      return (line : childLines)

renderOptLine :: HelpTreeOpts -> TreeOption -> IO (Maybe String)
renderOptLine opts opt
  | shouldSkipOption opt (treeAll opts) = return Nothing
  | otherwise = do
      let meta = if not (null (optShort opt)) && not (null (optLong opt))
                 then optShort opt ++ ", " ++ optLong opt
                 else if not (null (optLong opt))
                 then optLong opt
                 else if not (null (optShort opt))
                 then optShort opt
                 else optName opt
          desc = optDescription opt
      metaStyled <- styleText meta (HelpTree.options (theme opts)) opts
      descStyled <- styleText desc (description (theme opts)) opts
      return $ Just $ "  " ++ metaStyled ++ " … " ++ descStyled

renderText :: TreeCommand -> HelpTreeOpts -> IO String
renderText cmd opts = do
  nameStyled <- styleText (cmdName cmd) (command (theme opts)) opts
  optLines <- fmap catMaybes $ mapM (renderOptLine opts) (cmdOptions cmd)
  treeLines <- renderTextLines cmd "" 0 opts
  return $ intercalate "\n" ([nameStyled] ++ optLines ++ if null treeLines then [] else [""] ++ treeLines)
  where
    catMaybes = mapMaybe id

optionToJson :: TreeOption -> Value
optionToJson opt = object $ concat
  [ ["type" .= ("option" :: String)]
  , ["name" .= optName opt]
  , ["description" .= optDescription opt | not (null (optDescription opt))]
  , ["short" .= optShort opt | not (null (optShort opt))]
  , ["long" .= optLong opt | not (null (optLong opt))]
  , ["default" .= optDefaultVal opt | not (null (optDefaultVal opt))]
  , ["required" .= optRequired opt]
  , ["takes_value" .= optTakesValue opt]
  ]

argumentToJson :: TreeArgument -> Value
argumentToJson arg = object $ concat
  [ ["type" .= ("argument" :: String)]
  , ["name" .= argName arg]
  , ["description" .= argDescription arg | not (null (argDescription arg))]
  , ["required" .= argRequired arg]
  ]

cmdToJson :: TreeCommand -> HelpTreeOpts -> Int -> Value
cmdToJson cmd opts depth = object $ concat
  [ ["type" .= ("command" :: String)]
  , ["name" .= cmdName cmd]
  , ["description" .= cmdDescription cmd | not (null (cmdDescription cmd))]
  , ["options" .= filterOpts | not (null filterOpts)]
  , ["arguments" .= filterArgs | not (null filterArgs)]
  , ["subcommands" .= filterSubs | not (null filterSubs)]
  ]
  where
    filterOpts = map optionToJson (filter (\opt -> not (shouldSkipOption opt (treeAll opts))) (cmdOptions cmd))
    filterArgs = map argumentToJson (filter (\arg -> not (shouldSkipArgument arg (treeAll opts))) (cmdArguments cmd))
    canRecurse = case depthLimit opts of
                   Just dl -> depth < dl
                   Nothing -> True
    filterSubs = if canRecurse
                 then map (\sub -> cmdToJson sub opts (depth + 1)) (filter (\sub -> not (shouldSkipCommand sub opts)) (cmdSubcommands cmd))
                 else []

findByPath :: TreeCommand -> [String] -> TreeCommand
findByPath cmd [] = cmd
findByPath cmd (token:tokens) =
  case filter (\sub -> cmdName sub == token) (cmdSubcommands cmd) of
    (sub:_) -> findByPath sub tokens
    []      -> cmd

runHelpTree :: TreeCommand -> HelpTreeInvocation -> IO ()
runHelpTree root invocation = do
  hSetEncoding stdout utf8
  let opts = invocationOpts invocation
      selected = findByPath root (invocationPath invocation)
  if output opts == Json
    then BLC.putStrLn (encode (cmdToJson selected opts 0))
    else do
      txt <- renderText selected opts
      putStrLn txt
      putStrLn ""
      putStrLn $ "Use `" ++ cmdName root ++ " <COMMAND> --help` for full details on arguments and flags."
