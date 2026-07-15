{-|
Module      : Main
Description : Demonstrations and verification for Part V (bordism realizability)
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Entry point for the Part V computational verification. Prints the Kitaev-chain
Z2 invariant table across the phase transition, the detected phase boundary in
the @(mu, t)@ plane, and the cluster-state SPT string order with its
symmetry-breaking degradation, then runs all QuickCheck properties. Exits
non-zero on any verification failure.
-}
module Main (main) where

import Control.Monad (forM_)
import System.Exit (exitFailure, exitSuccess)
import Text.Printf (printf)

import Kitaev
import Stabilizer
import Properties (runAllProperties)
import Proofs (runAllProofs)

main :: IO ()
main = do
  putStrLn "=== Bordism Realizability (Part V): Formal Verification ==="
  putStrLn ""

  putStrLn "--- Demonstration 1: Kitaev-chain Z2 invariant sweep (t = 1, Delta = 1) ---"
  printKitaevSweep
  putStrLn ""

  putStrLn "--- Demonstration 2: phase boundary in the (mu, t) plane (detected vs analytic) ---"
  printPlaneBoundary
  putStrLn ""

  putStrLn "--- Demonstration 3: cluster-state Z2 x Z2 SPT string order ---"
  printClusterDemo
  putStrLn ""

  propsOk <- runAllProperties
  putStrLn ""
  proofsOk <- runAllProofs
  putStrLn ""
  if propsOk && proofsOk
    then putStrLn "All verifications passed." >> exitSuccess
    else putStrLn "VERIFICATION FAILURES DETECTED." >> exitFailure

-- | Kitaev-chain invariant table as @mu@ sweeps across the transition at @|mu| = 2@.
printKitaevSweep :: IO ()
printKitaevSweep = do
  putStrLn "     mu    winding  Majorana    gap      phase"
  let mus  = [ -3.0, -2.5, -2.1, -1.9, -1.0, 0.0, 1.0, 1.9, 2.1, 2.5, 3.0 ]
      rows = muSweep 1.0 1.0 mus
  forM_ rows $ \(SweepRow mu w m g lbl) ->
    printf "  %6.2f    %2d       %+2d      %7.4f    %s\n" mu w m g lbl

-- | Detected boundary (from the invariant) vs the analytic value @2t@, for several @t@.
printPlaneBoundary :: IO ()
printPlaneBoundary = do
  putStrLn "     t     detected    analytic (2t)"
  forM_ [0.5, 1.0, 1.5, 2.0] $ \t ->
    case detectBoundary t 1.0 of
      Just b  -> printf "  %5.2f     %6.3f       %6.3f\n" t b (planeBoundary t)
      Nothing -> printf "  %5.2f     (none)       %6.3f\n" t (planeBoundary t)

-- | Cluster-state string order, no-local-order check, and symmetry-breaking degradation.
printClusterDemo :: IO ()
printClusterDemo = do
  let n = 8 :: Int
      a = 0 :: Int
      b = 6 :: Int
      gens = clusterGenerators n
  case mkStringWindow n a b of
    Nothing -> error "printClusterDemo: invalid window literal"
    Just w  -> do
      printf "  chain n = %d, string S(%d,%d) with %d X-factors\n" n a b (numX w)
      printf "  <S>    = %+d   (expect +1: nonlocal SPT order)\n" (stringOrder w)
      printf "  <Z_3>  = %+d   (expect  0: no local order parameter)\n"
             (expectation gens (single n LZ 3))
      putStrLn "  string order under symmetry-breaking rotation U(theta):"
      putStrLn "       theta     <S(theta)>    cos^m theta"
      forM_ [0.0, pi / 8, pi / 4, 3 * pi / 8, pi / 2] $ \th ->
        printf "     %7.4f      %8.5f      %8.5f\n"
               th (stringOrderRotated w th) (cos th ^ numX w)
