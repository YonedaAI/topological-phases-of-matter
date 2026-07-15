{-|
Module      : GNS
Description : Explicit Gelfand-Naimark-Segal construction on a matrix algebra
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

The GNS construction of Section~5 (\Cref{prop:gns}, "GNS is a functor"), made
fully explicit for a state @phi_rho(a) = Tr(rho a)@ on @M_n(C)@.

We use the basis of matrix units @{E_ij}@ of @M_n(C)@, indexed by @p = i*n + j@,
as a spanning set for the PRE-Hilbert space on which @<a,b>_phi = phi(a* b)@ is
a (possibly degenerate) sesquilinear form. Concretely:

  * the Gram matrix is @G[(i,j),(k,l)] = <E_ij, E_kl>_phi
      = Tr(rho E_ij* E_kl) = delta_{ik} rho_{lj}@;
  * the representation is left multiplication,
      @pi(a) E_kl = a E_kl = sum_m a_{mk} E_ml@;
  * the cyclic vector is the class of the unit, @Omega = sum_i E_ii@.

Important caveat: the paper's GNS space is the QUOTIENT @M_n / N_phi@ by the
null space @N_phi = {a : phi(a* a) = 0}@ of this form (\Cref{prop:gns}'s
construction, via the Cauchy-Schwarz inequality). 'gnsData' does not construct
that quotient --- it keeps the full @n^2@-dimensional pre-Hilbert space on the
matrix units, with @G@ a Gram matrix that is positive semidefinite but only
honestly positive DEFINITE (i.e.\ @rank(G) = n^2@) when @phi@ is faithful, for
instance any strictly positive density matrix. For a non-faithful state ---
any pure state is the sharpest example --- @N_phi@ is a nontrivial left ideal
and the true GNS Hilbert space @M_n / N_phi@ has dimension @rank(G) < n^2@.
The reconstruction identity @<Omega, pi(a) Omega>_G = Tr(rho a) = phi(a)@ that
'gnsExpectation' checks is unaffected by this (it is an identity about the
specific vectors @Omega@, @pi(a) Omega@ and is true on the pre-quotient space
exactly because it is true after quotienting), but the PRE-quotient space's
dimension, @n^2@, must not be reported as "the GNS Hilbert space dimension" in
general; 'gnsRank' computes the true dimension @rank(G)@ from @G@'s spectrum
without constructing the quotient explicitly, and 'Proofs.gnsRankCheck'
verifies both regimes concretely (full rank @n^2@ on a faithful state, strictly
smaller rank on a pure state).
-}
module GNS
  ( GNSData(..)
  , gnsData
  , gnsRepresent
  , gnsExpectation
  , gnsGramHermitian
  , gnsRank
  ) where

import Data.Complex (Complex, conjugate)

import Core
  ( Matrix, Vector, dim, adjoint, approxEqMat, hermitianEigenvalues
  , fromRowsUnsafe, matRows, matCols, toRows )

-- | The explicit GNS data attached to a density matrix @rho@ on @M_n(C)@:
-- the Gram matrix on the @n^2@-dimensional space of matrix units, the cyclic
-- vector, and the algebra dimension @n@.
data GNSData = GNSData
  { gnsGram   :: Matrix  -- ^ @n^2 x n^2@ Gram matrix @G@
  , gnsCyclic :: Vector  -- ^ cyclic vector @Omega@ (length @n^2@)
  , gnsDim    :: Int     -- ^ dimension @n@ of the underlying matrix algebra
  }

-- | Build the explicit GNS data for the state @phi_rho@ on @M_n(C)@.
gnsData :: Matrix -> GNSData
gnsData rho = GNSData
  { gnsGram   = gram
  , gnsCyclic = omega
  , gnsDim    = n
  }
  where
    n :: Int
    n = dim rho
    -- G[(i,j),(k,l)] = delta_{ik} * rho_{lj}
    gram :: Matrix
    gram =
      fromRowsUnsafe
        [ [ if i == k then (toRows rho !! l) !! j else 0
          | k <- [0 .. n - 1], l <- [0 .. n - 1] ]
        | i <- [0 .. n - 1], j <- [0 .. n - 1] ]
    -- Omega = sum_i E_ii : coefficient 1 at flat index (i,i)
    omega :: Vector
    omega = [ if i == j then 1 else 0 | i <- [0 .. n - 1], j <- [0 .. n - 1] ]

-- | The GNS representation matrix @pi(a)@ (of size @n^2 x n^2@) as left
-- multiplication by @a@ on matrix units: @pi(a) E_kl = sum_m a_{mk} E_ml@.
-- Requires @a@ to be @n x n@; fails loudly (naming the shapes involved)
-- rather than crashing on an unhelpful out-of-bounds index if it is not.
gnsRepresent :: Int -> Matrix -> Matrix
gnsRepresent n a
  | matRows a /= n || matCols a /= n =
      error ("GNS.gnsRepresent: expected a " ++ show n ++ "x" ++ show n
             ++ " matrix, got " ++ show (matRows a) ++ "x" ++ show (matCols a))
  | otherwise =
      fromRowsUnsafe
        [ [ coeff (r `div` n) (r `mod` n) (c `div` n) (c `mod` n)
          | c <- [0 .. n * n - 1] ]
        | r <- [0 .. n * n - 1] ]
  where
    -- row (m,l) <- col (k,l'): pi(a)_{(m,l),(k,l')} = a_{mk} * delta_{l l'}
    coeff :: Int -> Int -> Int -> Int -> Complex Double
    coeff m l k l'
      | l == l'   = (toRows a !! m) !! k
      | otherwise = 0

-- | The GNS expectation @<Omega, pi(a) Omega>_G@, computed from the explicit
-- Gram matrix, representation, and cyclic vector. Equals @Tr(rho a) = phi(a)@.
gnsExpectation :: Matrix -> Matrix -> Complex Double
gnsExpectation rho a =
  let g     = gnsData rho
      n     = gnsDim g
      omega = gnsCyclic g
      piA   = gnsRepresent n a
      w     = matVec piA omega                -- pi(a) Omega
      gw    = matVec (gnsGram g) w            -- G (pi(a) Omega)
  in sum (zipWith (*) (map conjugate omega) gw)  -- Omega^* G pi(a) Omega

-- | Matrix times vector.
matVec :: Matrix -> Vector -> Vector
matVec m v = [ sum (zipWith (*) row v) | row <- toRows m ]

-- | Sanity check: the GNS Gram matrix is Hermitian (an inner product, up to
-- the possible degeneracy discussed in the module documentation).
gnsGramHermitian :: Matrix -> Bool
gnsGramHermitian rho =
  let g = gnsGram (gnsData rho)
  in approxEqMat 1e-9 g (adjoint g)

-- | The true dimension of the GNS Hilbert space @M_n / N_phi@: the rank of
-- the Hermitian, positive semidefinite Gram matrix, read off its spectrum
-- via 'hermitianEigenvalues' rather than by constructing the quotient
-- explicitly. Equals @n^2@ exactly when @phi@ is faithful; strictly smaller
-- for a non-faithful state such as a pure state (see the module
-- documentation). Checked concretely by 'Proofs.gnsRankCheck'.
gnsRank :: Matrix -> Int
gnsRank rho = length (filter (> tol) (hermitianEigenvalues (gnsGram (gnsData rho))))
  where
    tol :: Double
    tol = 1e-7
