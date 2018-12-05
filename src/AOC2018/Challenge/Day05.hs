{-# OPTIONS_GHC -Wno-unused-imports   #-}
{-# OPTIONS_GHC -Wno-unused-top-binds #-}

-- |
-- Module      : AOC2018.Challenge.Day05
-- Copyright   : (c) Justin Le 2018
-- License     : BSD3
--
-- Maintainer  : justin@jle.im
-- Stability   : experimental
-- Portability : non-portable
--
-- Day 5.  See "AOC2018.Solver" for the types used in this module!
--
-- After completing the challenge, it is recommended to:
--
-- *   Replace "AOC2018.Prelude" imports to specific modules (with explicit
--     imports) for readability.
-- *   Remove the @-Wno-unused-imports@ and @-Wno-unused-top-binds@
--     pragmas.
-- *   Replace the partial type signatures underscores in the solution
--     types @_ :~> _@ with the actual types of inputs and outputs of the
--     solution.  You can delete the type signatures completely and GHC
--     will recommend what should go in place of the underscores.

module AOC2018.Challenge.Day05 (
    day05a
  , day05b
  ) where

import           AOC2018.Prelude
import qualified Data.Map        as M
import qualified Data.Set        as S

anti :: Char -> Char -> Bool
anti x y = toLower x == toLower y
        && isUpper x /= isUpper y

cons :: Char -> String -> String
x `cons` (y:xs)
    | anti x y  = xs
    | otherwise = x:y:xs
x `cons` []     = [x]

react :: String -> String
react = foldr cons []

day05a :: String :~> Int
day05a = MkSol
    { sParse = Just . strip
    , sShow  = show
    , sSolve = Just . length . react
    }

day05b :: String :~> Int
day05b = MkSol
    { sParse = Just . strip
    , sShow  = show
    , sSolve = \xs -> fmap snd
                    . minimumVal
                    . M.fromSet (length . react . (`remove` xs))
                    . S.fromList
                    $ ['a' .. 'z']
    }
  where
    remove c = filter $ (/= c) . toLower
