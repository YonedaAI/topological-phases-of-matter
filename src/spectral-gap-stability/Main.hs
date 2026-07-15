{-|
Module      : Main
Description : Demonstrations and verification for Part III (spectral gap stability).
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Entry point for the transverse-field Ising computation accompanying \"The Uniformly
Gapped Substack\". Prints the spectral-gap table across the coupling @g in [0,2]@ for
several chain lengths, exhibits the finite-size gap shrinking at the gapless
discriminant @Sigma = {g = 1}@, runs a perturbation experiment illustrating the
Theorem III-A Lipschitz bound, then executes the QuickCheck property suite
("Properties") and the deterministic theorem-instance suite ("Proofs"). Exits
non-zero if any verification fails.
-}
module Main (main) where

import Control.Monad (forM_)
import System.Exit (exitFailure, exitSuccess)
import Text.Printf (printf)

import Properties (runAllProperties)
import Proofs (runAllInstances)
import TFIM

-- | Couplings sampled for the gap table.
gValues :: [Double]
gValues = [0.0, 0.25 .. 2.0]

-- | Chain lengths for the finite-size study.
nValues :: [Int]
nValues = [4, 6, 8]

-- | Print the spectral-gap table. For each length we diagonalize once per coupling
-- and report the 1-gap, the 2-gap (physical gap above a two-fold ground sector), and
-- the exact thermodynamic gap @2|1-g|@.
gapTable :: IO ()
gapTable = do
  putStrLn "--- Spectral gap of H(g) = -sum_i Z_i Z_{i+1} - g sum_i X_i (open chain) ---"
  putStrLn "    columns:  g | 1-gap (lam1-lam0) | 2-gap (lam2-lam0) | exact 2|1-g|"
  forM_ nValues $ \n -> do
    printf "  N = %d:\n" n
    forM_ gValues $ \g -> do
      let es = spectrum (config n g)
      case es of
        (e0 : e1 : e2 : _) ->
          printf "    g=%.2f   1-gap=%.4f   2-gap=%.4f   exact=%.4f\n"
            g (e1 - e0) (e2 - e0) (freeFermionGap g)
        _ -> printf "    g=%.2f   (spectrum too small)\n" g
  putStrLn ""

-- | Show the finite-size gap at the discriminant deepening toward zero with N.
criticalTrend :: IO ()
criticalTrend = do
  putStrLn "--- Finite-size gap at the discriminant g=1 (deepens toward 0 with N) ---"
  forM_ nValues $ \n ->
    case gapAt (config n 1.0) of
      Just gp -> printf "    N=%d   gap(g=1) = %.4f\n" n gp
      Nothing -> printf "    N=%d   gap(g=1) = <undefined>\n" n
  putStrLn "    The thermodynamic gap at g=1 is exactly 0: this is the gapless"
  putStrLn "    discriminant Sigma. No finite-N value proves it -- the model is"
  putStrLn "    known gapless only from its exact Jordan-Wigner solution."
  putStrLn ""

-- | Perturbation experiment at @g = 1.5@ (a gapped paramagnet): several deterministic
-- longitudinal fields, each confirming the Theorem III-A bound
-- @|gap(H+V) - gap(H)| <= 2||V||@.
perturbationExperiment :: IO ()
perturbationExperiment = do
  putStrLn "--- Perturbation stability at g=1.5 (Theorem III-A: |dgap| <= 2||V||) ---"
  let cfg = config 6 1.5
      fields =
        [ replicate 6 0.1
        , [0.1, -0.1, 0.1, -0.1, 0.1, -0.1]
        , [0.2, 0.0, -0.2, 0.2, 0.0, -0.2]
        , replicate 6 0.25
        ]
  case gapAt cfg of
    Nothing -> putStrLn "    (unexpected: gapAt returned Nothing for a valid config)"
    Just g0 -> do
      printf "    unperturbed gap = %.4f\n" g0
      forM_ fields $ \vs ->
        case perturbedGap cfg vs of
          Nothing -> putStrLn "    (unexpected: perturbedGap returned Nothing)"
          Just gp -> do
            let dg  = abs (gp - g0)
                bnd = 2 * fieldOpNorm vs
                tag = if dg <= bnd + 1.0e-9 then "OK" else "VIOLATION"
            printf "    V=%-30s gap=%.4f  |dgap|=%.4f <= %.4f  %s\n"
              (show vs) gp dg bnd tag
  putStrLn ""

main :: IO ()
main = do
  putStrLn "=== Spectral Gap Stability (Part III): Formal Verification ==="
  putStrLn ""
  gapTable
  criticalTrend
  perturbationExperiment
  okProperties <- runAllProperties
  putStrLn ""
  okInstances <- runAllInstances
  putStrLn ""
  if okProperties && okInstances
    then putStrLn "All verifications passed." >> exitSuccess
    else putStrLn "VERIFICATION FAILURES DETECTED." >> exitFailure
