{-|
Module      : TenfoldWay
Description : The free-fermion tenfold-way periodic table and its Bott
              periodicities (Definition 5.7, Proposition 5.8, Table 1).
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Companion code for Part IV.  Encodes the Altland--Zirnbauer tenfold way as the
antidiagonal formula @G(s,d) = seq((s - d) mod p)@, with @p = 2@ for the two
complex classes and @p = 8@ for the eight real classes, and the Bott sequences

  d_C = [ Z, 0 ]
  d_R = [ Z, Z2, Z2, 0, 2Z, 0, 0, 0 ].

The strong-invariant groups so produced reproduce Table 1 of the paper; the
periodicities and the antidiagonal invariance @G(s,d) = G(s+1,d+1)@ are
Proposition 5.8, and are exercised by "Properties".
-}
module TenfoldWay
  ( -- * Abelian invariant groups
    Ab(..)
    -- * Symmetry classes
  , AZClass(..)
  , Field(..)
  , field
  , symIndex
    -- * Bott sequences and table entries
  , complexSeq
  , realSeq
  , entryComplex
  , entryReal
  , invariant
    -- * Rendering
  , renderTable
  ) where

import Data.List (intercalate)

-- | The abelian groups that occur as strong topological invariants.  @TwoZ@ is
-- @2Z@, isomorphic to @Z@ but retained as the distinguished degree-4 real
-- generator in the physics convention.
data Ab = Zero | Z | Z2 | TwoZ
  deriving (Eq, Show)

-- | Real or complex Altland--Zirnbauer class.
data Field = Real | Complex
  deriving (Eq, Show)

-- | The ten Altland--Zirnbauer symmetry classes.  The eight real classes come
-- first (symmetry index @0..7@), then the two complex classes.
data AZClass
  = AI | BDI | D | DIII | AII | CII | C | CI   -- real, s = 0..7
  | A | AIII                                    -- complex, s = 0, 1
  deriving (Eq, Show, Enum, Bounded)

-- | Which field a class belongs to.
field :: AZClass -> Field
field A    = Complex
field AIII = Complex
field _    = Real

-- | The Cartan symmetry index @s@ of a class (mod 8 for real, mod 2 for
-- complex).
symIndex :: AZClass -> Int
symIndex cls = case cls of
  AI -> 0; BDI -> 1; D -> 2; DIII -> 3; AII -> 4; CII -> 5; C -> 6; CI -> 7
  A -> 0; AIII -> 1

-- | The complex Bott sequence @d_C@, period 2.
complexSeq :: [Ab]
complexSeq = [Z, Zero]

-- | The real Bott sequence @d_R@, period 8.
realSeq :: [Ab]
realSeq = [Z, Z2, Z2, Zero, TwoZ, Zero, Zero, Zero]

-- | Strong invariant of a complex class with symmetry index @s@ in dimension
-- @d@: @d_C((s - d) mod 2)@.
entryComplex :: Int -> Int -> Ab
entryComplex s d = complexSeq !! ((s - d) `mod` 2)

-- | Strong invariant of a real class with symmetry index @s@ in dimension @d@:
-- @d_R((s - d) mod 8)@.  Note Haskell's @mod@ with a positive modulus already
-- returns a value in @[0, p-1]@, so negative @s - d@ is handled correctly.
entryReal :: Int -> Int -> Ab
entryReal s d = realSeq !! ((s - d) `mod` 8)

-- | The strong topological invariant group @G(class, d)@ of Definition 5.7.
invariant :: AZClass -> Int -> Ab
invariant cls d = case field cls of
  Complex -> entryComplex (symIndex cls) d
  Real    -> entryReal (symIndex cls) d

-- ---------------------------------------------------------------------------
-- Rendering (regenerates Table 1)
-- ---------------------------------------------------------------------------

showAb :: Ab -> String
showAb Zero = "0"
showAb Z    = "Z"
showAb Z2   = "Z2"
showAb TwoZ = "2Z"

-- | Render the tenfold-way table over dimensions @0..7@ exactly as Table 1.
renderTable :: String
renderTable = unlines (header : sep : map row [minBound .. maxBound])
  where
    dims        = [0 .. 7] :: [Int]
    cell s      = pad 5 s
    pad n s     = s ++ replicate (max 0 (n - length s)) ' '
    header      = pad 7 "class" ++ "| " ++ intercalate " " (map (cell . ('d' :) . show) dims)
    sep         = replicate 7 '-' ++ "+" ++ replicate (6 * length dims) '-'
    row cls     = pad 7 (show cls) ++ "| "
                   ++ intercalate " " [ cell (showAb (invariant cls d)) | d <- dims ]
