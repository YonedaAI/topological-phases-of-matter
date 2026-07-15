{-|
Module      : Main
Description : Demonstrations and verification for Part II (positivity, C*-norms)
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Entry point for the formal verification accompanying
/Positivity, C*-Norms, and Condensed State Spaces of Quasi-Local Algebras/.

Runs concrete demonstrations of positivity checking, the GNS construction, and
the Bloch-ball geometry of qubit states, then executes the QuickCheck property
suite and the deterministic identity checks. Exits non-zero if any verification
fails.
-}
module Main (main) where

import Data.Complex (Complex(..), realPart, magnitude)
import Text.Printf (printf)
import System.Exit (exitFailure, exitSuccess)

import Core
  ( Matrix, mmul, adjoint, mtrace, stateEval, fromRowsUnsafe
  , hermitianEigenvalues, minEigenvalue, spectralNorm
  , isPositiveEig, isPositiveDefinite, mkDensity, isDensity, purity
  , densityFromBloch, blochVector )
import GNS (gnsExpectation, gnsData, gnsDim, gnsGramHermitian, gnsRank)
import CrossedProduct (XP, xpUnsafe, xpMul, xpUnit, includeXP, restrictXP, xpApprox)
import Properties (runAllProperties)
import Proofs (runAllProofs)

-- | A sample @3 x 3@ density matrix built as @M M* / Tr(M M*)@.
sampleDensity :: Matrix
sampleDensity = mkDensity . fromRowsUnsafe $
  [ [1 :+ 0,     0 :+ 1, 0.5 :+ 0]
  , [0 :+ (-1),  2 :+ 0, 0 :+ 0  ]
  , [0.5 :+ 0,   0 :+ 0, 1 :+ 0  ] ]

-- | Show a real number to four decimals.
fmt :: Double -> String
fmt = printf "%.4f"

-- | Demonstration 1: positivity of a state, two ways.
demoPositivity :: IO ()
demoPositivity = do
  putStrLn "--- Demonstration 1: positivity of a state ---"
  let rho = sampleDensity
  putStrLn ("  Tr(rho)              = " ++ fmt (realPart (mtrace rho)))
  putStrLn ("  eigenvalues of rho   = "
            ++ unwords (map fmt (hermitianEigenvalues rho)))
  putStrLn ("  min eigenvalue       = " ++ fmt (minEigenvalue rho))
  putStrLn ("  positive (eigenvalue)= " ++ show (isPositiveEig rho))
  putStrLn ("  positive-definite    = " ++ show (isPositiveDefinite rho))
  putStrLn ("  valid density matrix = " ++ show (isDensity rho))
  putStrLn ("  purity Tr(rho^2)     = " ++ fmt (purity rho))

-- | Demonstration 2: the GNS construction recovers the state.
--
-- The pre-GNS spanning set of matrix units has dimension @n^2@, but the true
-- GNS Hilbert space is the quotient @M_n \/ N_phi@ by the (possibly
-- nontrivial) null space of @phi@'s sesquilinear form; @n^2@ only equals the
-- true dimension when @phi@ is faithful. We show both counts, and contrast a
-- faithful state (here, where they agree) with a pure state (where they do
-- not) --- see @GNS@'s module documentation and 'GNS.gnsRank'.
demoGNS :: IO ()
demoGNS = do
  putStrLn "--- Demonstration 2: GNS construction ---"
  let rho = sampleDensity
      g   = gnsData rho
      a   = fromRowsUnsafe
              [ [0 :+ 0, 1 :+ 0, 0 :+ 0]
              , [1 :+ 0, 0 :+ 0, 0 :+ 1]
              , [0 :+ 0, 0 :+ (-1), 0 :+ 0] ]
      lhs = gnsExpectation rho a
      rhs = stateEval rho a
      n2  = gnsDim g * gnsDim g
      rk  = gnsRank rho
  putStrLn ("  pre-GNS spanning-set dim n^2 = " ++ show n2
            ++ "  (n = " ++ show (gnsDim g) ++ ")")
  putStrLn ("  true GNS dimension rank(G)   = " ++ show rk
            ++ if rk == n2 then "  (faithful state: they agree)"
                            else "  (non-faithful: strictly less than n^2)")
  putStrLn ("  Gram matrix Hermitian = " ++ show (gnsGramHermitian rho))
  putStrLn ("  <Omega, pi(a) Omega>  = " ++ showC lhs)
  putStrLn ("  Tr(rho a)             = " ++ showC rhs)
  putStrLn ("  reconstruction error  = " ++ fmt (magnitude (lhs - rhs)))
  let rhoPure = densityFromBloch (0, 0, 1)  -- the pure state |0><0| on M_2
      gPure   = gnsData rhoPure
      n2Pure  = gnsDim gPure * gnsDim gPure
      rkPure  = gnsRank rhoPure
  putStrLn ("  contrast, pure |0><0| on M_2: n^2 = " ++ show n2Pure
            ++ ", true rank(G) = " ++ show rkPure
            ++ "  (n^2 overstates the GNS dimension here)")

-- | Demonstration 3: the Bloch ball.
demoBloch :: IO ()
demoBloch = do
  putStrLn "--- Demonstration 3: Bloch-ball geometry of qubit states ---"
  mapM_ report
    [ ("north pole (0,0,1)   ", (0, 0, 1))
    , ("interior (0.3,-0.4,0.2)", (0.3, -0.4, 0.2))
    , ("centre   (0,0,0)     ", (0, 0, 0))
    , ("outside  (0.8,0.8,0.8)", (0.8, 0.8, 0.8)) ]
  where
    report :: (String, (Double, Double, Double)) -> IO ()
    report (lbl, r@(x, y, z)) = do
      let rho = densityFromBloch r
          nrm = sqrt (x * x + y * y + z * z)
          rBack = blochVector rho
      putStrLn ("  " ++ lbl ++ " |r| = " ++ fmt nrm
                ++ "  positive = " ++ show (isPositiveEig rho)
                ++ "  purity = " ++ fmt (purity rho)
                ++ "  r(rho) = " ++ showR3 rBack)

-- | Demonstration 4: the C*-identity and norm.
demoNorm :: IO ()
demoNorm = do
  putStrLn "--- Demonstration 4: the C*-identity ||a* a|| = ||a||^2 ---"
  let a = fromRowsUnsafe [ [1 :+ 1, 2 :+ 0], [0 :+ (-1), 1 :+ 0] ]
      na = spectralNorm a
      nStar = spectralNorm (adjoint a `mmul` a)
  putStrLn ("  ||a||                = " ++ fmt na)
  putStrLn ("  ||a* a||             = " ++ fmt nStar)
  putStrLn ("  ||a||^2              = " ++ fmt (na * na))
  putStrLn ("  C*-identity holds    = " ++ show (abs (nStar - na * na) < 1e-6))

-- | Demonstration 5: the finite-level Bellissard crossed product and its
-- functoriality in finite quotients (Theorem II-C).
demoCrossedProduct :: IO ()
demoCrossedProduct = do
  putStrLn "--- Demonstration 5: finite crossed product C(Z/n) x (Z/6), Theorem II-C ---"
  let a, b :: XP
      a = xpUnsafe [ [1 :+ 0, 0], [0, 1 :+ 0], replicate 2 0, replicate 2 0, replicate 2 0, replicate 2 0 ]
      b = xpUnsafe [ [0, 1 :+ 0], [1 :+ 0, 0], replicate 2 0, replicate 2 0, replicate 2 0, replicate 2 0 ]
      unitOk    = xpApprox 1e-9 (xpMul 6 6 (xpUnit 6 6) (includeXP 2 6 a)) (includeXP 2 6 a)
      homOk     = xpApprox 1e-9 (includeXP 2 6 (xpMul 2 6 a b))
                                (xpMul 6 6 (includeXP 2 6 a) (includeXP 2 6 b))
      injective = xpApprox 1e-9 (restrictXP 2 (includeXP 2 6 a)) a
  putStrLn ("  dim C(Z/2) x (Z/6)   = " ++ show (2 * 6 :: Int) ++ "  (n * bigN)")
  putStrLn ("  dim C(Z/6) x (Z/6)   = " ++ show (6 * 6 :: Int) ++ "  (n = bigN, regular case)")
  putStrLn ("  unit acts as identity on include(a) = " ++ show unitOk)
  putStrLn ("  include(a b) = include(a) include(b) = " ++ show homOk)
  putStrLn ("  restrict . include = id (injectivity)  = " ++ show injective)

-- | Format a complex number.
showC :: Complex Double -> String
showC (re :+ im) = fmt re ++ (if im >= 0 then " + " else " - ") ++ fmt (abs im) ++ "i"

-- | Format a real 3-vector.
showR3 :: (Double, Double, Double) -> String
showR3 (x, y, z) = "(" ++ fmt x ++ ", " ++ fmt y ++ ", " ++ fmt z ++ ")"

main :: IO ()
main = do
  putStrLn "=== Part II: Positivity, C*-Norms, and Condensed State Spaces ==="
  putStrLn "=== Formal verification on finite-dimensional C*-algebras ==="
  putStrLn ""
  demoPositivity
  putStrLn ""
  demoGNS
  putStrLn ""
  demoBloch
  putStrLn ""
  demoNorm
  putStrLn ""
  demoCrossedProduct
  putStrLn ""
  propsOk <- runAllProperties
  putStrLn ""
  proofsOk <- runAllProofs
  putStrLn ""
  if propsOk && proofsOk
    then do
      putStrLn "All verifications passed."
      exitSuccess
    else do
      putStrLn "VERIFICATION FAILURES DETECTED."
      exitFailure
