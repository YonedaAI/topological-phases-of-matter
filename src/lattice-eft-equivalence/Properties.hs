{-|
Module      : Main (properties test-suite)
Description : QuickCheck properties for Part IV: monoid laws, the group-completion
              universal property, and Bott periodicity of the tenfold way.
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Each property corresponds to a labelled claim of the paper.  The suite exits
nonzero if any property fails, so it doubles as a regression gate.

Arbitrary instances are given on local newtype wrappers (@WElt@, @WGElt@) rather
than on the library types directly, so the suite compiles with no orphan
instances under @-Wall -Wextra -Werror@.
-}
module Main (main) where

import qualified Data.Map.Strict as Map
import System.Exit (exitFailure, exitSuccess)
import Test.QuickCheck hiding (scale)

import Monoid
import TenfoldWay

-- ---------------------------------------------------------------------------
-- Generators (wrapped in local newtypes to avoid orphan Arbitrary instances)
-- ---------------------------------------------------------------------------

-- Fixed small generator alphabet keeps the reachable classes finite.
genAlphabet :: [String]
genAlphabet = ["a", "b", "t"]

-- | Generator for monoid elements over the fixed alphabet.
eltGen :: Gen Elt
eltGen = do
  es <- vectorOf (length genAlphabet) (choose (0, 3) :: Gen Integer)
  pure (foldr plus zero (zipWith scale (map fromIntegral es) (map gen genAlphabet)))

-- | Wrapped element: a local type, so its Arbitrary instance is not an orphan.
newtype WElt = WElt Elt deriving (Show)

instance Arbitrary WElt where
  arbitrary = WElt <$> eltGen

-- | Wrapped group-completion element.
newtype WGElt = WGElt GElt deriving (Show)

instance Arbitrary WGElt where
  arbitrary = WGElt <$> (GElt <$> eltGen <*> eltGen)

-- | Small integers for symmetry-index / dimension arguments.
newtype SmallInt = SmallInt Int deriving (Show)

instance Arbitrary SmallInt where
  arbitrary = SmallInt <$> choose (-20, 20)

-- The free commutative monoid on the alphabet (cancellative).
free3 :: CMonoid
free3 = freeCMonoid genAlphabet

-- 'eltGen' only ever uses generators from 'genAlphabet', which is exactly
-- 'free3's declared alphabet, so every generated element should honestly
-- respect it (guards 'respectsAlphabet' and 'freeCMonoid's stored generator
-- list against regressions).
prop_respectsOwnAlphabet :: WElt -> Bool
prop_respectsOwnAlphabet (WElt x) = respectsAlphabet free3 x

-- 'gen' itself enforces no alphabet (validation is opt-in via
-- 'respectsAlphabet'), so an out-of-alphabet generator must be honestly
-- reported as violating a stricter monoid's declared list: the negative case
-- 'prop_respectsOwnAlphabet' alone does not exercise.
prop_violatesForeignAlphabet :: Bool
prop_violatesForeignAlphabet = not (respectsAlphabet (freeCMonoid ["a"]) (gen "b"))

-- ---------------------------------------------------------------------------
-- Monoid laws (Proposition 3.3, checked on the concrete carrier)
-- ---------------------------------------------------------------------------

prop_assoc :: WElt -> WElt -> WElt -> Bool
prop_assoc (WElt x) (WElt y) (WElt z) = plus (plus x y) z == plus x (plus y z)

prop_comm :: WElt -> WElt -> Bool
prop_comm (WElt x) (WElt y) = plus x y == plus y x

prop_unit :: WElt -> Bool
prop_unit (WElt x) = plus x zero == x && plus zero x == x

-- Normal forms respect the operation in the toy monoid (congruence check).
prop_toyCongruence :: WElt -> WElt -> Bool
prop_toyCongruence (WElt x) (WElt y) =
  normalise toyMonoid (plus x y)
    == normalise toyMonoid (plus (normalise toyMonoid x) (normalise toyMonoid y))

-- ---------------------------------------------------------------------------
-- Group completion is an abelian group (Theorem 4.2(i))
-- ---------------------------------------------------------------------------

prop_gAssoc :: WGElt -> WGElt -> WGElt -> Bool
prop_gAssoc (WGElt g) (WGElt h) (WGElt k) =
  eqG free3 (plusG (plusG g h) k) (plusG g (plusG h k))

prop_gComm :: WGElt -> WGElt -> Bool
prop_gComm (WGElt g) (WGElt h) = eqG free3 (plusG g h) (plusG h g)

prop_gIdentity :: WGElt -> Bool
prop_gIdentity (WGElt g) = eqG free3 (plusG g zeroG) g

prop_gInverse :: WGElt -> Bool
prop_gInverse (WGElt g) = eqG free3 (plusG g (negG g)) zeroG

-- The four group laws above were checked only on the cancellative free3; the
-- non-cancellative toyMonoid exercises 'eqG's witness-search path instead of
-- plain structural equality, so it needs its own coverage.

prop_toyGAssoc :: WGElt -> WGElt -> WGElt -> Bool
prop_toyGAssoc (WGElt g) (WGElt h) (WGElt k) =
  eqG toyMonoid (plusG (plusG g h) k) (plusG g (plusG h k))

prop_toyGComm :: WGElt -> WGElt -> Bool
prop_toyGComm (WGElt g) (WGElt h) = eqG toyMonoid (plusG g h) (plusG h g)

prop_toyGIdentity :: WGElt -> Bool
prop_toyGIdentity (WGElt g) = eqG toyMonoid (plusG g zeroG) g

prop_toyGInverse :: WGElt -> Bool
prop_toyGInverse (WGElt g) = eqG toyMonoid (plusG g (negG g)) zeroG

-- ---------------------------------------------------------------------------
-- eqG is an equivalence relation and a congruence, on the non-cancellative
-- toyMonoid (Definition 4.1 / Proposition 4.4's witness-search path)
-- ---------------------------------------------------------------------------

-- | Padding a 'GElt's both sides by the same element preserves its class in
-- @K(M)@ for /any/ 'CMonoid': @(a,b) ~ (a+e,b+e)@ always, via the trivial
-- witness @0@. Used below to build pairs that are genuinely 'eqG'-equivalent
-- by construction, rather than relying on rare random coincidence.
padG :: Elt -> GElt -> GElt
padG e (GElt x y) = GElt (plus x e) (plus y e)

prop_toyEqReflexive :: WGElt -> Bool
prop_toyEqReflexive (WGElt g) = eqG toyMonoid g g

prop_toyEqSymmetric :: WGElt -> WGElt -> Bool
prop_toyEqSymmetric (WGElt g) (WGElt h) = eqG toyMonoid g h == eqG toyMonoid h g

-- g ~ h ~ k by construction (each a padding of the last); transitivity says
-- g ~ k must also hold.
prop_toyEqTransitive :: WGElt -> WElt -> WElt -> Bool
prop_toyEqTransitive (WGElt g) (WElt e1) (WElt e2) =
  eqG toyMonoid g h && eqG toyMonoid h k && eqG toyMonoid g k
  where
    h = padG e1 g
    k = padG e2 h

-- plusG respects eqG: if g ~ g' then g+k ~ g'+k.
prop_toyPlusGCongruence :: WGElt -> WElt -> WGElt -> Bool
prop_toyPlusGCongruence (WGElt g) (WElt e) (WGElt k) =
  eqG toyMonoid g g' && eqG toyMonoid (plusG g k) (plusG g' k)
  where
    g' = padG e g

-- ---------------------------------------------------------------------------
-- Stable equality / cancellation (Proposition 4.4)
-- ---------------------------------------------------------------------------

-- gamma is injective on a cancellative (free) monoid.
prop_gammaInjectiveFree :: WElt -> WElt -> Property
prop_gammaInjectiveFree (WElt x) (WElt y) =
  eqG free3 (gamma x) (gamma y) === (x == y)

-- The toy monoid is genuinely non-cancellative: a is nonzero yet collapses.
prop_toyCollapsesA :: Bool
prop_toyCollapsesA =
  normalise toyMonoid (gen "a") /= zero
    && isTrivialG toyMonoid (gamma (gen "a"))

-- ...and t^m never collapses (it is not absorbed).
prop_toyKeepsT :: Positive Int -> Bool
prop_toyKeepsT (Positive m) =
  not (isTrivialG toyMonoid (gamma (scale (fromIntegral m) (gen "t"))))

-- Distinct multiples of t remain distinct in K(toyMonoid): the completion carries
-- a free Z on [t], so K(M) = Z (Example 4.5), not 0.
prop_toyTPowersDistinct :: Positive Int -> Positive Int -> Property
prop_toyTPowersDistinct (Positive i) (Positive j) =
  i /= j ==>
    not (eqG toyMonoid (gamma (scale (fromIntegral i) (gen "t")))
                       (gamma (scale (fromIntegral j) (gen "t"))))

-- ---------------------------------------------------------------------------
-- Universal property (Theorem 4.2(iii))
-- ---------------------------------------------------------------------------

-- A weight hom respecting the toy relation must send a to 0.
toyHom :: Integer -> Integer -> Hom
toyHom wt wb = weightHom (Map.fromList [("a", 0), ("t", wt), ("b", wb)])

-- fbar . gamma == f  (the factorization of the universal property).
prop_inducedFactors :: Integer -> Integer -> WElt -> Bool
prop_inducedFactors wt wb (WElt x) =
  induced (toyHom wt wb) (gamma x) == toyHom wt wb x

-- fbar is a group homomorphism.
prop_inducedHom :: Integer -> Integer -> WGElt -> WGElt -> Bool
prop_inducedHom wt wb (WGElt g) (WGElt h) =
  induced f (plusG g h) == induced f g + induced f h
  where f = toyHom wt wb

-- fbar is well defined: adding the collapsing generator a leaves the class in
-- K(toyMonoid) unchanged (gamma a = gamma 0), so the image must be unchanged.
prop_inducedWellDefined :: Integer -> Integer -> WGElt -> Bool
prop_inducedWellDefined wt wb (WGElt g) =
  eqG toyMonoid g h && induced f g == induced f h
  where
    f = toyHom wt wb
    h = plusG g (gamma (gen "a"))

-- ---------------------------------------------------------------------------
-- Bott periodicity of the tenfold way (Proposition 5.8)
-- ---------------------------------------------------------------------------

prop_realPeriod8 :: SmallInt -> SmallInt -> Bool
prop_realPeriod8 (SmallInt s) (SmallInt d) =
  entryReal s d == entryReal s (d + 8)

prop_realPeriodS8 :: SmallInt -> SmallInt -> Bool
prop_realPeriodS8 (SmallInt s) (SmallInt d) =
  entryReal s d == entryReal (s + 8) d

prop_complexPeriod2 :: SmallInt -> SmallInt -> Bool
prop_complexPeriod2 (SmallInt s) (SmallInt d) =
  entryComplex s d == entryComplex s (d + 2)

prop_antidiagReal :: SmallInt -> SmallInt -> Bool
prop_antidiagReal (SmallInt s) (SmallInt d) =
  entryReal s d == entryReal (s + 1) (d + 1)

prop_antidiagComplex :: SmallInt -> SmallInt -> Bool
prop_antidiagComplex (SmallInt s) (SmallInt d) =
  entryComplex s d == entryComplex (s + 1) (d + 1)

-- Landmark entries of Table 1 (spot checks).
prop_landmarks :: Bool
prop_landmarks = and
  [ entryReal 2 1 == Z2       -- class D, d=1  : Kitaev chain
  , entryReal 2 2 == Z        -- class D, d=2  : p+ip superconductor
  , entryReal 4 2 == Z2       -- class AII, d=2: quantum spin Hall
  , entryReal 4 3 == Z2       -- class AII, d=3: 3D topological insulator
  , entryReal 0 0 == Z        -- class AI, d=0
  , entryComplex 0 2 == Z     -- class A, d=2  : integer quantum Hall
  , entryComplex 1 1 == Z     -- class AIII, d=1: SSH chain
  , entryComplex 0 1 == Zero  -- class A, d=1  : no invariant
  , invariant D 1 == Z2       -- via the class-indexed interface
  , invariant AIII 1 == Z
  ]

-- | The full 10x8 Table 1 matrix (paper Table~1 / \Cref{tab:tenfold},
-- lines 1098-1108), transcribed verbatim, so a regression in any single
-- entry -- not just the periodicity shape or the five landmarks above -- is
-- caught, not only the aggregate periodicity/antidiagonal shape.
table1 :: [(AZClass, [Ab])]
table1 =
  [ (AI,   [Z,    Zero, Zero, Zero, TwoZ, Zero, Z2,   Z2  ])
  , (BDI,  [Z2,   Z,    Zero, Zero, Zero, TwoZ, Zero, Z2  ])
  , (D,    [Z2,   Z2,   Z,    Zero, Zero, Zero, TwoZ, Zero])
  , (DIII, [Zero, Z2,   Z2,   Z,    Zero, Zero, Zero, TwoZ])
  , (AII,  [TwoZ, Zero, Z2,   Z2,   Z,    Zero, Zero, Zero])
  , (CII,  [Zero, TwoZ, Zero, Z2,   Z2,   Z,    Zero, Zero])
  , (C,    [Zero, Zero, TwoZ, Zero, Z2,   Z2,   Z,    Zero])
  , (CI,   [Zero, Zero, Zero, TwoZ, Zero, Z2,   Z2,   Z   ])
  , (A,    [Z,    Zero, Z,    Zero, Z,    Zero, Z,    Zero])
  , (AIII, [Zero, Z,    Zero, Z,    Zero, Z,    Zero, Z   ])
  ]

prop_table1Regression :: Bool
prop_table1Regression = and
  [ invariant cls d == expected
  | (cls, row) <- table1
  , (d, expected) <- zip [0 .. 7] row
  ]

-- ---------------------------------------------------------------------------
-- Runner
-- ---------------------------------------------------------------------------

-- | Run a named property and report; return whether it passed.
run :: Testable p => String -> p -> IO Bool
run name p = do
  putStr ("  " ++ name ++ " ... ")
  res <- quickCheckResult p
  pure (isSuccess res)

main :: IO ()
main = do
  putStrLn "== QuickCheck properties for Part IV =="
  results <- sequence
    [ run "monoid associativity"          prop_assoc
    , run "monoid commutativity"          prop_comm
    , run "monoid unit"                   prop_unit
    , run "toy normal form is a congruence" prop_toyCongruence
    , run "K(M) associativity"            prop_gAssoc
    , run "K(M) commutativity"            prop_gComm
    , run "K(M) identity"                 prop_gIdentity
    , run "K(M) inverses"                 prop_gInverse
    , run "toy K(M) associativity"        prop_toyGAssoc
    , run "toy K(M) commutativity"        prop_toyGComm
    , run "toy K(M) identity"             prop_toyGIdentity
    , run "toy K(M) inverses"             prop_toyGInverse
    , run "toy eqG reflexive"             prop_toyEqReflexive
    , run "toy eqG symmetric"             prop_toyEqSymmetric
    , run "toy eqG transitive"            prop_toyEqTransitive
    , run "toy plusG respects eqG"        prop_toyPlusGCongruence
    , run "generated elements respect their alphabet" prop_respectsOwnAlphabet
    , run "foreign generator violates a stricter alphabet" (once prop_violatesForeignAlphabet)
    , run "gamma injective on free monoid" prop_gammaInjectiveFree
    , run "toy monoid collapses a"        (once prop_toyCollapsesA)
    , run "toy monoid keeps t^m"          prop_toyKeepsT
    , run "toy K(M) = Z: t powers distinct" prop_toyTPowersDistinct
    , run "induced hom factors f"         prop_inducedFactors
    , run "induced is a homomorphism"     prop_inducedHom
    , run "induced is well defined"       prop_inducedWellDefined
    , run "real table 8-periodic in d"    prop_realPeriod8
    , run "real table 8-periodic in s"    prop_realPeriodS8
    , run "complex table 2-periodic in d" prop_complexPeriod2
    , run "real antidiagonal invariance"  prop_antidiagReal
    , run "complex antidiagonal invariance" prop_antidiagComplex
    , run "landmark table entries"        (once prop_landmarks)
    , run "full 10x8 Table 1 regression"  (once prop_table1Regression)
    ]
  if and results
    then putStrLn "ALL PROPERTIES PASSED" >> exitSuccess
    else putStrLn "SOME PROPERTIES FAILED" >> exitFailure
