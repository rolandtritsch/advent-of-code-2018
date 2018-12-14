-- |
-- Module      : AOC.Challenge.Day13
-- Copyright   : (c) Justin Le 2018
-- License     : BSD3
--
-- Maintainer  : justin@jle.im
-- Stability   : experimental
-- Portability : non-portable
--
-- Day 13.  See "AOC.Solver" for the types used in this module!

module AOC.Challenge.Day13 (
    day13a
  , day13b
  ) where

import           AOC.Solver            ((:~>)(..))
import           Control.Lens          (view, makeLenses, (^.), (<.>), ifoldMapOf, folded, lined, over)
import           Data.Functor.Foldable (hylo)
import           Data.Map              (Map)
import           Data.Ord              (comparing)
import           Data.These            (These(..), fromThese)
import           Linear                (V2(..), _x, _y)
import qualified Data.Map              as M

type Point = V2 Int

data Turn = TurnNW      -- ^ a forward-slash mirror @/@
          | TurnNE      -- ^ a backwards-slash mirror @\\@
          | TurnInter   -- ^ a four-way intersection
  deriving (Eq, Show, Ord)

data Dir = DN | DE | DS | DW
  deriving (Eq, Show, Ord, Enum, Bounded)

data Cart = C { _cDir   :: Dir
              , _cTurns :: Int
              }
  deriving (Eq, Show)

makeLenses ''Cart

-- | It's 'Point', but with a newtype wrapper so we have an 'Ord' that
-- sorts by y first, then x
newtype ScanPoint = SP { _getSP :: Point }
  deriving (Eq, Show, Num)

instance Ord ScanPoint where
    compare = comparing (view _y . _getSP)
           <> comparing (view _x . _getSP)

-- | All turns on the map.  We don't need to store the straight-line paths
-- because they're effectively a vacuum.
type World = Map Point     Turn
type Carts = Map ScanPoint Cart

-- | Step a single cart through the world.
stepCart :: World -> ScanPoint -> Cart -> (ScanPoint, Cart)
stepCart w (SP p) c = (SP p', maybe id turner (M.lookup p' w) c)
  where
    p' = p + case c ^. cDir of
      DN -> V2 0    (-1)
      DE -> V2 1    0
      DS -> V2 0    1
      DW -> V2 (-1) 0
    turner = \case
      TurnNW    -> over cDir $ \case DN -> DE; DE -> DN; DS -> DW; DW -> DS
      TurnNE    -> over cDir $ \case DN -> DW; DW -> DN; DS -> DE; DE -> DS
      TurnInter -> over cTurns (+ 1) . over cDir (turnWith (c ^. cTurns))
    turnWith i = case i `mod` 3 of
      0 -> turnLeft
      1 -> id
      _ -> turnLeft . turnLeft . turnLeft
    turnLeft DN = DW
    turnLeft DE = DN
    turnLeft DS = DE
    turnLeft DW = DS

-- | One of the ways a single step of the simulation can go.
data CartLog a = CLCrash Point a      -- ^ A crash, at a given point
               | CLTick        a      -- ^ No crashes, just a normal timestep
               | CLDone  Point        -- ^ Only one car left, at a given point
  deriving (Show, Functor)

-- | Given a (waiting, done) queue, emit a 'CartLog' event with an updated
-- (waiting, done) queue.
stepCarts
    :: World
    -> (Carts, Carts)
    -> CartLog (Carts, Carts)
stepCarts w (waiting, done) = case M.minViewWithKey waiting of
    Nothing -> case M.minViewWithKey done of
      Just ((SP lastPos, _), M.null->True) -> CLDone lastPos
      _                                    -> CLTick (done, M.empty)
    Just (uncurry (stepCart w) -> (p, c), waiting') ->
      case M.lookup p (waiting' <> done) of
        Nothing -> CLTick             (waiting'           , M.insert p c done)
        Just _  -> CLCrash (_getSP p) (M.delete p waiting', M.delete p done  )

-- | Given a folding function, simulate on events emitted by 'stepCarts'.
simulateWith
    :: (CartLog a -> a)
    -> World
    -> Carts
    -> a
simulateWith f w c = (f `hylo` stepCarts w) (c, M.empty)

day13a :: (World, Carts) :~> Point
day13a = MkSol
    { sParse = Just . parseWorld
    , sShow  = \(V2 x y) -> show x ++ "," ++ show y
    , sSolve = Just . uncurry (simulateWith firstCrash)
    }
  where
    firstCrash (CLCrash p _) = p
    firstCrash (CLTick    p) = p
    firstCrash (CLDone  p  ) = p


day13b :: (World, Carts) :~> Point
day13b = MkSol
    { sParse = Just . parseWorld
    , sShow  = \(V2 x y) -> show x ++ "," ++ show y
    , sSolve = Just . uncurry (simulateWith lastPoint)
    }
  where
    lastPoint (CLCrash _ p) = p
    lastPoint (CLTick    p) = p
    lastPoint (CLDone  p  ) = p

parseWorld :: String -> (World, Carts)
parseWorld = maybe mempty (fromThese mempty mempty)
           . ifoldMapOf (lined <.> folded) (uncurry classify)
  where
    classify y x = \case
        '/'  -> Just . This $ M.singleton p      TurnNW
        '\\' -> Just . This $ M.singleton p      TurnNE
        '+'  -> Just . This $ M.singleton p      TurnInter
        'v'  -> Just . That $ M.singleton (SP p) (C DS 0)
        '^'  -> Just . That $ M.singleton (SP p) (C DN 0)
        '>'  -> Just . That $ M.singleton (SP p) (C DE 0)
        '<'  -> Just . That $ M.singleton (SP p) (C DW 0)
        _    -> Nothing
      where
        p = V2 x y