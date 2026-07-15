{-|
Module      : Ising
Description : Transverse-field Ising chain and its Lieb-Robinson light cone (Paper I).
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

The running example of "Condensed Locality" (Example 3.6, Section 8). Builds the
transverse-field Ising Hamiltonian on an open chain, evolves a single-site
operator in the Heisenberg picture, and measures the commutator norm
@c(x,t) = || [sigma^x_0(t), sigma^x_x] ||@ that exhibits the light cone. A
least-squares fit of the front position against time recovers a group velocity,
which is bounded by the analytic Lieb-Robinson velocity of Proposition 3.2.
-}
module Ising
  ( -- * Single-site operators
    pauliI, pauliX, pauliY, pauliZ
  , siteOp
    -- * Model and dynamics
  , tfimH
  , heisenberg
    -- * Light cone
  , coneAtTime
  , frontPosition
  , fitVelocity
  ) where

import Data.Complex (Complex(..))
import LinAlg
  ( Matrix, addM, mmul, scaleM, adjoint, commutator, kron, expiH, opNorm )

-- | Pauli / identity single-site matrices.
pauliI, pauliX, pauliY, pauliZ :: Matrix
pauliI = [[1, 0], [0, 1]]
pauliX = [[0, 1], [1, 0]]
pauliY = [[0, 0 :+ (-1)], [0 :+ 1, 0]]
pauliZ = [[1, 0], [0, -1]]

-- | Embed a single-site operator at site @j@ of an @n@-site chain
-- (@0 <= j < n@): the Kronecker product of identities with @op@ at slot @j@.
-- @n@ must be positive (the underlying 'foldr1' is partial on an empty chain); a non-positive
-- @n@ raises a clear error rather than the cryptic \"Prelude.foldr1: empty list\".
siteOp :: Int -> Int -> Matrix -> Matrix
siteOp n j op
  | n <= 0    = error ("siteOp: chain length must be positive, got " ++ show n)
  | otherwise = foldr1 kron [ if k == j then op else pauliI | k <- [0 .. n - 1] ]

-- | Transverse-field Ising Hamiltonian on an open chain of @n@ sites:
-- @H = -J sum_k Z_k Z_{k+1} - h sum_k X_k@. @n@ must be positive, for the same reason as
-- 'siteOp' (the field terms alone are enough to make the underlying 'foldr1' total whenever
-- @n >= 1@; this guard covers the @n <= 0@ case with a clear error).
tfimH :: Int -> Double -> Double -> Matrix
tfimH n jj hh
  | n <= 0    = error ("tfimH: chain length must be positive, got " ++ show n)
  | otherwise = foldr1 addM (bonds ++ fields)
  where
    bonds  = [ scaleM (negate jj :+ 0)
                 (mmul (siteOp n k pauliZ) (siteOp n (k + 1) pauliZ))
             | k <- [0 .. n - 2] ]
    fields = [ scaleM (negate hh :+ 0) (siteOp n k pauliX) | k <- [0 .. n - 1] ]

-- | Heisenberg evolution @A(t) = e^{i t H} A e^{-i t H}@.
heisenberg :: Matrix -> Double -> Matrix -> Matrix
heisenberg h t a = mmul (mmul u a) udag
  where
    u    = expiH t h
    udag = adjoint u

-- | Commutator-norm row @c(x,t) = || [sigma^x_0(t), sigma^x_x] ||@ for
-- @x = 0 .. n-1@ at a fixed time @t@; the evolved operator is computed once.
coneAtTime :: Int -> Double -> Double -> Double -> [(Int, Double)]
coneAtTime n jj hh t =
  [ (x, opNorm (commutator a0t (siteOp n x pauliX))) | x <- [0 .. n - 1] ]
  where
    a0t = heisenberg (tfimH n jj hh) t (siteOp n 0 pauliX)

-- | Front position at a fixed time: the largest @x@ whose commutator norm
-- exceeds a fraction @rel@ of the row maximum.
frontPosition :: Double -> [(Int, Double)] -> Int
frontPosition rel row =
  let cmax = maximum (0 : map snd row)
      thr  = rel * cmax
      hits = [ x | (x, c) <- row, c >= thr ]
  in if null hits then 0 else maximum hits

-- | Least-squares slope through the origin, @v = sum(t*x) / sum(t^2)@, from a
-- list of @(time, front position)@ pairs.
fitVelocity :: [(Double, Int)] -> Double
fitVelocity pts =
  let num = sum [ t * fromIntegral x | (t, x) <- pts ]
      den = sum [ t * t | (t, _) <- pts ]
  in if den == 0 then 0 else num / den
