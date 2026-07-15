{-|
Module      : LinAlg
Description : Minimal dense complex linear algebra for the TFIM light-cone demo.
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

A small, dependency-free complex-matrix toolkit used by "Ising": products,
adjoints, Kronecker products, the Heisenberg unitary @e^{i t H}@ by scaling and
squaring with a Taylor core, and the operator norm by power iteration on
@M^* M@. Dimensions here are small (a spin chain of a few sites), so clarity is
preferred over performance.
-}
module LinAlg
  ( -- * Types
    Cx
  , Matrix
    -- * Basic operations
  , dim
  , identM
  , addM
  , subM
  , scaleM
  , mmul
  , adjoint
  , commutator
  , kron
  , isWellFormedMatrix
    -- * Analytic operations
  , expiH
  , opNorm
  , opNormConverged
  ) where

import Data.Complex (Complex(..), magnitude, conjugate, realPart)
import Data.List (transpose)

-- 'foldl'' below resolves through Prelude (base >= 4.20 / GHC >= 9.10 re-exports the
-- Foldable class method), verified against this project's actual toolchain (GHC 9.14.1,
-- base-4.22.0.0): a fresh `cabal build` under -Wall -Wextra -Werror is clean with no explicit
-- import of it. An earlier revision added `import Data.List (foldl', transpose)` plus
-- `import Prelude hiding (foldl')` to force an explicit, portable source for it; that combination
-- is in fact what a GHC/base old enough to lack the Prelude re-export needs, but on such a
-- toolchain the `hiding` clause hides a name Prelude never exported in the first place, which
-- is exactly what -Wdodgy-imports (also under -Werror) flags. Since this project pins a
-- toolchain that already has the re-export, the plain, warning-free form is used instead.

-- | Complex scalar.
type Cx = Complex Double

-- | Dense complex matrix as a list of rows.
--
-- 'Matrix' does not itself enforce rectangularity or squareness: 'mmul', 'addM', 'subM', and
-- 'kron' all assume both arguments are rectangular (every row the same length) and, since
-- every matrix built by this module is square, that the row count equals the row length. If
-- that precondition is violated, 'zipWith'-based operations silently truncate to the shorter
-- dimension rather than raising an error. 'isWellFormedMatrix' checks the precondition; a
-- fully dimension-indexed type (or 'Either'-returning operations) would enforce it statically
-- instead, at the cost of a larger, more invasive rewrite of this numerically-sensitive
-- module (it feeds the paper's quoted light-cone data), which is why this module instead
-- documents the precondition and offers a predicate to check it.
type Matrix = [[Cx]]

-- | Number of rows (all matrices here are square).
dim :: Matrix -> Int
dim = length

-- | Identity matrix of a given size.
identM :: Int -> Matrix
identM n = [ [ if i == j then 1 else 0 | j <- [0 .. n - 1] ] | i <- [0 .. n - 1] ]

-- | Entrywise sum. Precondition: both matrices are rectangular and of equal dimensions (see
-- the 'Matrix' documentation); violating it truncates silently rather than erroring.
addM :: Matrix -> Matrix -> Matrix
addM = zipWith (zipWith (+))

-- | Entrywise difference. Same precondition as 'addM'.
subM :: Matrix -> Matrix -> Matrix
subM = zipWith (zipWith (-))

-- | Scalar multiple.
scaleM :: Cx -> Matrix -> Matrix
scaleM c = map (map (c *))

-- | Strict complex dot product.
dot :: [Cx] -> [Cx] -> Cx
dot xs ys = foldl' (+) 0 (zipWith (*) xs ys)

-- | Matrix product. Precondition: @a@'s row length equals @b@'s row count (both rectangular);
-- see the 'Matrix' documentation.
mmul :: Matrix -> Matrix -> Matrix
mmul a b = [ [ dot row col | col <- bt ] | row <- a ]
  where bt = transpose b

-- | A matrix is well-formed here if it is rectangular (every row has the same length as the
-- first) and square (that common row length equals the number of rows). This is the
-- precondition 'mmul', 'addM', 'subM', and 'kron' rely on but do not themselves check.
isWellFormedMatrix :: Matrix -> Bool
isWellFormedMatrix m = case map length m of
  []       -> True
  (c : cs) -> all (== c) cs && c == length m

-- | Conjugate transpose.
adjoint :: Matrix -> Matrix
adjoint = map (map conjugate) . transpose

-- | Commutator @[A,B] = AB - BA@.
commutator :: Matrix -> Matrix -> Matrix
commutator a b = subM (mmul a b) (mmul b a)

-- | Kronecker (tensor) product.
kron :: Matrix -> Matrix -> Matrix
kron a b = [ concat [ [ x * y | y <- rowB ] | x <- rowA ] | rowA <- a, rowB <- b ]

-- | Max absolute row sum (an operator-norm upper bound), used to set the
-- scaling in the matrix exponential.
infNorm :: Matrix -> Double
infNorm m = maximum (0 : [ foldl' (+) 0 [ magnitude z | z <- row ] | row <- m ])

-- | Matrix exponential @e^M@ by scaling and squaring with a Taylor core, truncated at a fixed
-- @kmax = 18@ Taylor terms after scaling @m@ down to operator-norm @<= 0.5@. This has no
-- independent error certificate (the review's caveat): @kmax = 18@ terms at that scale is
-- comfortably enough for double precision in practice (the @0.5@-scaled remainder after 18
-- terms is far below machine epsilon), but that is an argument from magnitude, not a checked
-- residual. 'opNormConverged' is the certificate this module does offer, on the operator-norm
-- side that the theorem checks actually consume.
expm :: Matrix -> Matrix
expm m = squareIt s (taylorSum scaled)
  where
    n      = dim m
    nrm    = infNorm m
    s      = if nrm <= 0.5 then 0 else ceiling (logBase 2 (nrm / 0.5)) :: Int
    scaled = scaleM ((1 / (2 ^ s :: Double)) :+ 0) m
    kmax   = 18 :: Int
    taylorSum x = go (identM n) (identM n) (1 :: Int)
      where
        go acc term k
          | k > kmax  = acc
          | otherwise =
              let term' = scaleM ((1 / fromIntegral k) :+ 0) (mmul term x)
              in go (addM acc term') term' (k + 1)
    squareIt j x
      | j <= 0    = x
      | otherwise = squareIt (j - 1) (mmul x x)

-- | The Heisenberg unitary @e^{i t H}@ for Hermitian @H@.
expiH :: Double -> Matrix -> Matrix
expiH t h = expm (scaleM (0 :+ t) h)

-- | Operator norm (largest singular value) via power iteration on @M^* M@,
-- seeded deterministically so the demo output is reproducible.
opNorm :: Matrix -> Double
opNorm m
  | dim m == 0 = 0
  | otherwise  = sqrt (max 0 (rayleigh g (powerIter g seed iters)))
  where
    g     = mmul (adjoint m) m
    n     = dim m
    seed  = normalizeV [ fromIntegral k :+ 0 | k <- [1 .. n] ]
    iters = 120 :: Int

-- | A convergence certificate for 'opNorm', without changing 'opNorm' itself (so its numeric
-- output, and everything computed from it, is untouched): re-run the same power iteration for
-- one additional step from the same seed and compare Rayleigh-quotient estimates. If the two
-- agree to within a tight relative tolerance, the fixed 120-iteration count had already
-- converged and 'opNorm' is a trustworthy estimate rather than an underestimate from an
-- unconverged iterate; this is the "residual check" alternative to a certified upper bound.
opNormConverged :: Matrix -> Bool
opNormConverged m
  | dim m == 0 = True
  | otherwise  = abs (est120 - est121) <= 1e-9 * max 1 est120
  where
    g      = mmul (adjoint m) m
    n      = dim m
    seed   = normalizeV [ fromIntegral k :+ 0 | k <- [1 .. n] ]
    est120 = sqrt (max 0 (rayleigh g (powerIter g seed 120)))
    est121 = sqrt (max 0 (rayleigh g (powerIter g seed 121)))

-- | Normalize a vector in the Euclidean norm.
normalizeV :: [Cx] -> [Cx]
normalizeV v =
  let nn = sqrt (foldl' (+) 0 [ magnitude z ^ (2 :: Int) | z <- v ])
  in if nn == 0 then v else [ z / (nn :+ 0) | z <- v ]

-- | Matrix times vector.
matVec :: Matrix -> [Cx] -> [Cx]
matVec a v = [ dot row v | row <- a ]

-- | @k@ steps of normalized power iteration.
powerIter :: Matrix -> [Cx] -> Int -> [Cx]
powerIter a v k
  | k <= 0    = v
  | otherwise = powerIter a (normalizeV (matVec a v)) (k - 1)

-- | Rayleigh quotient @<v, A v>@ for a normalized vector @v@.
rayleigh :: Matrix -> [Cx] -> Double
rayleigh a v = realPart (dot (map conjugate v) (matVec a v))
