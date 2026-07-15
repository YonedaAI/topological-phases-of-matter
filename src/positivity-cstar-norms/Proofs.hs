{-|
Module      : Proofs
Description : Deterministic checks of the paper's concrete identities
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Concrete, non-randomized verification of the identities used in the paper, on
fixed states and observables. Where 'Properties' samples, this module pins
down specific instances so the arithmetic can be read off and audited. These
are FINITE SANITY CHECKS on concrete numerical instances, not formal proofs of
the paper's (general, infinite-dimensional-algebra) theorem statements --- the
actual proofs are in @papers/latex/positivity-cstar-norms.tex@; what is
checked here is that the paper's equations hold on specific, hand-computable
examples, catching the kind of arithmetic slip a proof-read alone would miss.
Every check below cites the paper theorem or proposition it verifies, and
where it mirrors an equation from the paper, that equation is spelled out:

  * the GNS reconstruction @<Omega, pi(a) Omega> = Tr(rho a)@ on the maximally
    mixed and a pure qubit state (Section~5, \Cref{prop:gns} "GNS is a
    functor");
  * Cauchy-Schwarz for a fixed state (Section~5, the inequality used in the
    proof of \Cref{prop:gns});
  * agreement of the eigenvalue and Cholesky tests for positive
    DEFINITENESS on fixed positive-definite and indefinite matrices, a
    strictly interior notion (see 'posCheck'), and separately, the closed
    positive SEMIDEFINITE cone @A_+@ of \Cref{thm:statespace}, Theorem~II-A,
    checked including its boundary via 'semidefCheck' on @diag(1,0)@ (positive
    but singular: in @A_+@, yet rejected by Cholesky);
  * the Bloch-ball purities: @Tr(rho^2) = 1@ on the sphere, @= 1/2@ at the centre
    (\Cref{ex:bloch}, the @n=2@ instance of Theorem~II-A);
  * the true dimension of the GNS Hilbert space @M_n / N_phi@ via
    'GNS.gnsRank', confirming it equals @n^2@ on a faithful state but is
    strictly smaller on a pure state (\Cref{prop:gns}; see @GNS@'s module
    documentation for why the naive @n^2@ count is wrong in general);
  * the finite-level Bellissard crossed product of Section~9
    (\Cref{thm:crossed}, Theorem~II-C): the multiplicative unit, functoriality
    of the periodization map in finite quotients, its injectivity, and the
    diagonal copy of @C(Omega)@ (\Cref{prop:hullAF}) multiplying pointwise.

A note on Theorem~II-B (Aoki's solidification theorem, \Cref{thm:aoki}): it is
deliberately NOT represented by any check in this module. It is a statement
about the solidification of the connective algebraic @K@-theory of a
condensed ring --- an infinite-dimensional, homotopy-theoretic construction
(condensed spectra, solidification as a Bousfield localization) with no finite
computational shadow at the level of this package's finite-dimensional
matrix-algebra model. It is verified the way deep cited theorems are verified
in this series: by checking the paper's statement and proof sketch against the
literature (Aoki's paper, Clausen--Scholze), not by executable computation.
This is a scope boundary, not an oversight.
-}
module Proofs
  ( runAllProofs
  ) where

import Data.Complex (Complex(..), magnitude)

import Core
  ( Matrix, mmul, adjoint, smul, identity, fromRowsUnsafe, stateEval, purity
  , isPositiveDefinite, isPositiveEig, minEigenvalue, densityFromBloch
  , pauliX, pauliZ )
import GNS (gnsExpectation, gnsRank)
import CrossedProduct
  ( XP, xpUnsafe, xpUnit, xpMul, xpApprox, includeXP, restrictXP, diagEmbed )

-- | A single named check with a boolean outcome.
data Check = Check
  { checkName :: String
  , checkOk   :: Bool
  }

-- | Maximally mixed qubit state @I/2@.
rhoMixed :: Matrix
rhoMixed = smul (0.5 :+ 0) (identity 2)

-- | Pure qubit state @|0><0|@ (north pole of the Bloch sphere).
rhoNorth :: Matrix
rhoNorth = densityFromBloch (0, 0, 1)

-- | A generic single-qubit state in the interior of the Bloch ball.
rhoGeneric :: Matrix
rhoGeneric = densityFromBloch (0.3, -0.4, 0.5)

-- | GNS reconstruction check on a specific @(rho, a)@ pair: the defining
-- identity @<Omega, pi(a) Omega> = phi(a)@ of \Cref{prop:gns}, "GNS is a
-- functor" (Section~5).
gnsCheck :: String -> Matrix -> Matrix -> Check
gnsCheck lbl rho a = Check
  { checkName = "GNS reconstruction " ++ lbl
  , checkOk   = magnitude (gnsExpectation rho a - stateEval rho a) < 1e-9
  }

-- | Cauchy-Schwarz for the fixed state @rho@ and observables @a, b@: the
-- inequality @|phi(a* b)|^2 <= phi(a* a) phi(b* b)@ that makes @N_phi@ a left
-- ideal in the construction preceding \Cref{prop:gns} (Section~5).
cauchyCheck :: String -> Matrix -> Matrix -> Matrix -> Check
cauchyCheck lbl rho a b = Check
  { checkName = "Cauchy-Schwarz " ++ lbl
  , checkOk   = lhs <= rhs + 1e-9
  }
  where
    phi x = stateEval rho x
    lhs   = let m = magnitude (phi (adjoint a `mmul` b)) in m * m
    rhs   = realPart' (phi (adjoint a `mmul` a)) * realPart' (phi (adjoint b `mmul` b))
    realPart' :: Complex Double -> Double
    realPart' (re :+ _) = re

-- | Agreement of the eigenvalue and Cholesky tests for positive
-- DEFINITENESS on a fixed matrix, with the expected verdict (Section~4).
-- This is a strictly interior notion, stronger than membership in the
-- closed positive semidefinite cone @A_+@ of \Cref{thm:statespace},
-- Theorem~II-A: see 'semidefCheck' for the cone itself, including its
-- boundary.
posCheck :: String -> Matrix -> Bool -> Check
posCheck lbl m expected = Check
  { checkName = "positive-definiteness verdict " ++ lbl
  , checkOk   = isPositiveDefinite m == expected
                  && (minEigenvalue m > 0) == expected
  }

-- | Membership in the closed positive semidefinite cone @A_+@ of
-- \Cref{thm:statespace}, Theorem~II-A, via 'isPositiveEig' --- which, unlike
-- Cholesky, correctly includes the boundary: a positive but singular matrix
-- such as @diag(1,0)@ (eigenvalues @1, 0@) lies in @A_+@ even though it is
-- not positive DEFINITE.
semidefCheck :: String -> Matrix -> Bool -> Check
semidefCheck lbl m expected = Check
  { checkName = "closed cone A_+ verdict (semidefinite) " ++ lbl
  , checkOk   = isPositiveEig m == expected
  }

-- | The true dimension of the GNS Hilbert space @M_n / N_phi@, via
-- 'GNS.gnsRank', against the expected value (\Cref{prop:gns}; see @GNS@'s
-- module documentation).
gnsRankCheck :: String -> Matrix -> Int -> Check
gnsRankCheck lbl rho expected = Check
  { checkName = "GNS true dimension rank(G) " ++ lbl
  , checkOk   = gnsRank rho == expected
  }

-- | Purity check within tolerance, on the Bloch-ball instance of the state
-- space (\Cref{ex:bloch}, the @n=2@ case of \Cref{thm:statespace},
-- Theorem~II-A): pure states sit on the boundary sphere, @Tr(rho^2)=1@, and
-- the maximally mixed state sits at the centre, @Tr(rho^2)=1/2@.
purityCheck :: String -> Matrix -> Double -> Check
purityCheck lbl rho expected = Check
  { checkName = "purity " ++ lbl
  , checkOk   = abs (purity rho - expected) < 1e-9
  }

-- ---------------------------------------------------------------------------
-- Finite-level Bellissard crossed product (Section~9, Theorem~II-C)
-- ---------------------------------------------------------------------------

-- | A concrete element of the "top" crossed product @C(Z\/6) \\rtimes (Z\/6)@
-- (the regular case @X = G@), with two nonzero Fourier components.
xpTop :: XP
xpTop = xpUnsafe
  [ [1 :+ 0, 0, 0, 0, 0, 0]   -- g = 0 component: point mass at x = 0
  , [0, 1 :+ 0, 0, 0, 0, 0]   -- g = 1 component: point mass at x = 1
  , replicate 6 0
  , replicate 6 0
  , replicate 6 0
  , replicate 6 0
  ]

-- | A concrete element of the "sub" crossed product @C(Z\/2) \\rtimes (Z\/6)@.
xpSubA :: XP
xpSubA = xpUnsafe
  [ [1 :+ 0, 0], [0, 1 :+ 0], replicate 2 0, replicate 2 0, replicate 2 0, replicate 2 0 ]

-- | A second concrete element of @C(Z\/2) \\rtimes (Z\/6)@, used together with
-- 'xpSubA' to check the crossed-product functoriality identity on a
-- genuinely noncommuting pair.
xpSubB :: XP
xpSubB = xpUnsafe
  [ [0, 1 :+ 0], [1 :+ 0, 0], replicate 2 0, replicate 2 0, replicate 2 0, replicate 2 0 ]

-- | The finite crossed-product unit acts as a two-sided identity (a basic
-- @*@-algebra fact underlying \Cref{thm:crossed}, Theorem~II-C).
xpUnitCheck :: Check
xpUnitCheck = Check
  { checkName = "crossed-product unit is a two-sided identity (II-C)"
  , checkOk   =    xpApprox 1e-9 (xpMul 6 6 (xpUnit 6 6) xpTop) xpTop
                && xpApprox 1e-9 (xpMul 6 6 xpTop (xpUnit 6 6)) xpTop
  }

-- | Functoriality of the finite crossed product in finite quotients
-- (\Cref{thm:crossed}, Theorem~II-C): the periodization map
-- @include :: dalg_2 -> dalg_6@ is a @*@-homomorphism,
-- @include(a b) = include(a) include(b)@, checked on a concrete noncommuting
-- pair.
xpHomCheck :: Check
xpHomCheck = Check
  { checkName = "crossed-product inclusion is a homomorphism (II-C)"
  , checkOk   = xpApprox 1e-9
                  (includeXP 2 6 (xpMul 2 6 xpSubA xpSubB))
                  (xpMul 6 6 (includeXP 2 6 xpSubA) (includeXP 2 6 xpSubB))
  }

-- | Injectivity of the periodization map (\Cref{thm:crossed}, Theorem~II-C):
-- 'restrictXP' is a one-sided inverse of 'includeXP'.
xpInjectiveCheck :: Check
xpInjectiveCheck = Check
  { checkName = "crossed-product inclusion is injective (II-C)"
  , checkOk   = xpApprox 1e-9 (restrictXP 2 (includeXP 2 6 xpSubA)) xpSubA
  }

-- | The diagonal copy of @C(X)@ inside the crossed product multiplies
-- pointwise (\Cref{prop:hullAF}: @C(Omega)@ sits inside @dalg@ this way).
xpDiagCheck :: Check
xpDiagCheck = Check
  { checkName = "diagonal embedding multiplies pointwise (II-C, prop:hullAF)"
  , checkOk   = xpApprox 1e-9
                  (xpMul 6 6 (diagEmbed 6 fVec) (diagEmbed 6 gVec))
                  (diagEmbed 6 (zipWith (*) fVec gVec))
  }
  where
    fVec, gVec :: [Complex Double]
    fVec = [1, 2, 3, 4, 5, 6]
    gVec = [6, 5, 4, 3, 2, 1]

-- | All deterministic checks.
allChecks :: [Check]
allChecks =
  [ gnsCheck "on I/2 with sigma_x"      rhoMixed   pauliX
  , gnsCheck "on |0><0| with sigma_z"   rhoNorth   pauliZ
  , gnsCheck "on generic rho with sigma_x" rhoGeneric pauliX
  , cauchyCheck "on I/2, (sigma_x, sigma_z)" rhoMixed pauliX pauliZ
  , cauchyCheck "on |0><0|, (sigma_x, sigma_z)" rhoNorth pauliX pauliZ
  , posCheck "diag(2,3) is PD"   (fromRowsUnsafe [[2, 0], [0, 3]]) True
  , posCheck "diag(0,-1) not PD" (fromRowsUnsafe [[0, 0], [0, -1]]) False
  , semidefCheck "diag(2,3) is in A_+ (interior)"        (fromRowsUnsafe [[2, 0], [0, 3]])  True
  , semidefCheck "diag(1,0) is in A_+ (boundary, not PD)" (fromRowsUnsafe [[1, 0], [0, 0]]) True
  , semidefCheck "diag(0,-1) is not in A_+"               (fromRowsUnsafe [[0, 0], [0, -1]]) False
  , purityCheck "of pure |0><0|" rhoNorth 1.0
  , purityCheck "of mixed I/2"   rhoMixed 0.5
  , gnsRankCheck "on faithful I/2 equals n^2=4" rhoMixed 4
  , gnsRankCheck "on pure |0><0| equals n=2, not n^2=4" rhoNorth 2
  , xpUnitCheck
  , xpHomCheck
  , xpInjectiveCheck
  , xpDiagCheck
  ]

-- | Run every deterministic check; return 'True' iff all pass.
runAllProofs :: IO Bool
runAllProofs = do
  putStrLn "=== Deterministic Identity Checks ==="
  mapM_ report allChecks
  let passed = length (filter checkOk allChecks)
      total  = length allChecks
  putStrLn (show passed ++ "/" ++ show total ++ " checks passed")
  pure (all checkOk allChecks)
  where
    report :: Check -> IO ()
    report c =
      putStrLn ("  " ++ (if checkOk c then "OK  " else "FAIL") ++ "  " ++ checkName c)
