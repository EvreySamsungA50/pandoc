{-# LANGUAGE ScopedTypeVariables, FlexibleInstances #-}
{-
Copyright (C) 2006-2010 John MacFarlane <jgm@berkeley.edu>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
-}

{- |
   Module      : Text.Pandoc
   Copyright   : Copyright (C) 2006-2010 John MacFarlane
   License     : GNU GPL, version 2 or above

   Maintainer  : John MacFarlane <jgm@berkeley.edu>
   Stability   : alpha
   Portability : portable

This helper module exports the main writers, readers, and data
structure definitions from the Pandoc libraries.

A typical application will chain together a reader and a writer
to convert strings from one format to another.  For example, the
following simple program will act as a filter converting markdown
fragments to reStructuredText, using reference-style links instead of
inline links:

> module Main where
> import Text.Pandoc
> -- include the following two lines only if you're using ghc < 6.12:
> import Prelude hiding (getContents, putStrLn)
> import System.IO.UTF8
>
> markdownToRST :: String -> String
> markdownToRST =
>   (writeRST def {writerReferenceLinks = True}) . readMarkdown def
>
> main = getContents >>= putStrLn . markdownToRST

Note:  all of the readers assume that the input text has @'\n'@
line endings.  So if you get your input text from a web form,
you should remove @'\r'@ characters using @filter (/='\r')@.

-}

module Text.Pandoc
               (
               -- * Definitions
               module Text.Pandoc.Definition
               -- * Generics
               , module Text.Pandoc.Generic
               -- * Options
               , module Text.Pandoc.Options
               -- * Lists of readers and writers
               , readers
               , writers
               -- * Readers: converting /to/ Pandoc format
               , readMarkdown
               , readRST
               , readLaTeX
               , readHtml
               , readTextile
               , readDocBook
               , readNative
               -- * Writers: converting /from/ Pandoc format
               , Writer (..)
               , writeNative
               , writeMarkdown
               , writePlain
               , writeRST
               , writeLaTeX
               , writeConTeXt
               , writeTexinfo
               , writeHtml
               , writeHtmlString
               , writeDocbook
               , writeOpenDocument
               , writeMan
               , writeMediaWiki
               , writeTextile
               , writeRTF
               , writeODT
               , writeDocx
               , writeEPUB
               , writeFB2
               , writeOrg
               , writeAsciiDoc
               -- * Writer options used in writers
               , WriterOptions (..)
               , HTMLSlideVariant (..)
               , HTMLMathMethod (..)
               , CiteMethod (..)
               , defaultWriterOptions
               -- * Rendering templates and default templates
               , module Text.Pandoc.Templates
               -- * Version
               , pandocVersion
               -- * Miscellaneous
               , rtfEmbedImage
               , jsonFilter
               , ToJsonFilter(..)
             ) where

import Text.Pandoc.Definition
import Text.Pandoc.Generic
import Text.Pandoc.Readers.Markdown
import Text.Pandoc.Readers.RST
import Text.Pandoc.Readers.DocBook
import Text.Pandoc.Readers.LaTeX
import Text.Pandoc.Readers.HTML
import Text.Pandoc.Readers.Textile
import Text.Pandoc.Readers.Native
import Text.Pandoc.Writers.Native
import Text.Pandoc.Writers.Markdown
import Text.Pandoc.Writers.RST
import Text.Pandoc.Writers.LaTeX
import Text.Pandoc.Writers.ConTeXt
import Text.Pandoc.Writers.Texinfo
import Text.Pandoc.Writers.HTML
import Text.Pandoc.Writers.ODT
import Text.Pandoc.Writers.Docx
import Text.Pandoc.Writers.EPUB
import Text.Pandoc.Writers.FB2
import Text.Pandoc.Writers.Docbook
import Text.Pandoc.Writers.OpenDocument
import Text.Pandoc.Writers.Man
import Text.Pandoc.Writers.RTF
import Text.Pandoc.Writers.MediaWiki
import Text.Pandoc.Writers.Textile
import Text.Pandoc.Writers.Org
import Text.Pandoc.Writers.AsciiDoc
import Text.Pandoc.Templates
import Text.Pandoc.Shared
import Text.Pandoc.Options
import Data.ByteString.Lazy (ByteString)
import Data.Version (showVersion)
import Text.JSON.Generic
import Paths_pandoc (version)

-- | Version number of pandoc library.
pandocVersion :: String
pandocVersion = showVersion version

-- | Association list of formats and readers.
readers :: [(String, ReaderOptions -> String -> Pandoc)]
readers = [("native"       , \_ -> readNative)
          ,("json"         , \_ -> decodeJSON)
          ,("markdown"     , readMarkdown)
          ,("markdown+lhs" , \opt ->
                             readMarkdown opt{ readerLiterateHaskell = True })
          ,("rst"          , readRST)
          ,("rst+lhs"      , \opt ->
                             readRST opt{ readerLiterateHaskell = True })
          ,("docbook"      , readDocBook)
          ,("textile"      , readTextile) -- TODO : textile+lhs
          ,("html"         , readHtml)
          ,("latex"        , readLaTeX)
          ,("latex+lhs"    , \opt ->
                             readLaTeX opt{ readerLiterateHaskell = True })
          ]

data Writer = PureStringWriter   (WriterOptions -> Pandoc -> String)
            | IOStringWriter     (WriterOptions -> Pandoc -> IO String)
            | IOByteStringWriter (WriterOptions -> Pandoc -> IO ByteString)

-- | Association list of formats and writers.
writers :: [ ( String, Writer ) ]
writers = [
   ("native"       , PureStringWriter writeNative)
  ,("json"         , PureStringWriter $ \_ -> encodeJSON)
  ,("docx"         , IOByteStringWriter writeDocx)
  ,("odt"          , IOByteStringWriter writeODT)
  ,("epub"         , IOByteStringWriter writeEPUB)
  ,("fb2"          , IOStringWriter writeFB2)
  ,("html"         , PureStringWriter writeHtmlString)
  ,("html5"        , PureStringWriter $ \o ->
     writeHtmlString o{ writerHtml5 = True })
  ,("html+lhs"     , PureStringWriter $ \o ->
     writeHtmlString o{ writerLiterateHaskell = True })
  ,("html5+lhs"    , PureStringWriter $ \o ->
     writeHtmlString o{ writerLiterateHaskell = True,
                        writerHtml5 = True })
  ,("s5"           , PureStringWriter $ \o ->
     writeHtmlString o{ writerSlideVariant = S5Slides
                      , writerTableOfContents = False })
  ,("slidy"        , PureStringWriter $ \o ->
     writeHtmlString o{ writerSlideVariant = SlidySlides })
  ,("slideous"     , PureStringWriter $ \o ->
     writeHtmlString o{ writerSlideVariant = SlideousSlides })
  ,("dzslides"     , PureStringWriter $ \o ->
     writeHtmlString o{ writerSlideVariant = DZSlides
                      , writerHtml5 = True })
  ,("docbook"      , PureStringWriter writeDocbook)
  ,("opendocument" , PureStringWriter writeOpenDocument)
  ,("latex"        , PureStringWriter writeLaTeX)
  ,("latex+lhs"    , PureStringWriter $ \o ->
     writeLaTeX o{ writerLiterateHaskell = True })
  ,("beamer"       , PureStringWriter $ \o ->
     writeLaTeX o{ writerBeamer = True })
  ,("beamer+lhs"   , PureStringWriter $ \o ->
     writeLaTeX o{ writerBeamer = True, writerLiterateHaskell = True })
  ,("context"      , PureStringWriter writeConTeXt)
  ,("texinfo"      , PureStringWriter writeTexinfo)
  ,("man"          , PureStringWriter writeMan)
  ,("markdown"     , PureStringWriter writeMarkdown)
  ,("markdown+lhs" , PureStringWriter $ \o ->
     writeMarkdown o{ writerLiterateHaskell = True })
  ,("plain"        , PureStringWriter writePlain)
  ,("rst"          , PureStringWriter writeRST)
  ,("rst+lhs"      , PureStringWriter $ \o ->
     writeRST o{ writerLiterateHaskell = True })
  ,("mediawiki"    , PureStringWriter writeMediaWiki)
  ,("textile"      , PureStringWriter writeTextile)
  ,("rtf"          , PureStringWriter writeRTF)
  ,("org"          , PureStringWriter writeOrg)
  ,("asciidoc"     , PureStringWriter writeAsciiDoc)
  ]

{-# DEPRECATED jsonFilter "Use toJsonFilter instead" #-}
-- | Converts a transformation on the Pandoc AST into a function
-- that reads and writes a JSON-encoded string.  This is useful
-- for writing small scripts.
jsonFilter :: (Pandoc -> Pandoc) -> String -> String
jsonFilter f = encodeJSON . f . decodeJSON

-- | 'toJsonFilter' convert a function into a filter that reads pandoc's json output
-- from stdin, transforms it by walking the AST and applying the specified
-- function, and writes the result as json to stdout.  Usage example:
--
-- > -- capitalize.hs
-- > -- compile with:  ghc --make capitalize
-- > -- run with:      pandoc -t json | ./capitalize | pandoc -f json
-- >
-- > import Text.Pandoc
-- > import Data.Char (toUpper)
-- >
-- > main :: IO ()
-- > main = toJsonFilter capitalizeStrings
-- >
-- > capitalizeStrings :: Inline -> Inline
-- > capitalizeStrings (Str s) = Str $ map toUpper s
-- > capitalizeStrings x       = x
--
-- The function can be any type @(a -> a)@, @(a -> IO a)@, @(a -> [a])@,
-- or @(a -> IO [a])@, where @a@ is an instance of 'Data'.
-- So, for example, @a@ can be 'Pandoc', 'Inline', 'Block', ['Inline'],
-- ['Block'], 'Meta', 'ListNumberStyle', 'Alignment', 'ListNumberDelim',
-- 'QuoteType', etc. See 'Text.Pandoc.Definition'.
class ToJsonFilter a where
  toJsonFilter :: a -> IO ()

instance (Data a) => ToJsonFilter (a -> a) where
  toJsonFilter f = getContents
    >>= putStr . encodeJSON . (bottomUp f :: Pandoc -> Pandoc) . decodeJSON

instance (Data a) => ToJsonFilter (a -> IO a) where
  toJsonFilter f = getContents >>= (bottomUpM f :: Pandoc -> IO Pandoc) . decodeJSON
    >>= putStr . encodeJSON

instance (Data a) => ToJsonFilter (a -> [a]) where
  toJsonFilter f = getContents
    >>= putStr . encodeJSON . (bottomUp (concatMap f) :: Pandoc -> Pandoc) . decodeJSON

instance (Data a) => ToJsonFilter (a -> IO [a]) where
  toJsonFilter f = getContents
    >>= (bottomUpM (fmap concat . mapM f) :: Pandoc -> IO Pandoc) . decodeJSON
    >>= putStr . encodeJSON
