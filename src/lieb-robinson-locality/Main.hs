{-|
Module      : Main
Description : Light-cone demonstration and verification for Paper I.
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Entry point for the "Condensed Locality" companion code. Prints the F-function
constants of Section 2, computes the transverse-field Ising commutator-norm
light cone of Section 8, fits a front velocity and checks it against the
analytic Lieb-Robinson bound of Proposition 3.2 (computed via 'analyticVelocity'
and the TFIM F-norm of Example 3.6, not a disconnected formula), checks the
pointwise Lieb-Robinson bound of Theorem 3.1 on disjoint supports, then runs the
QuickCheck properties and the equational-reasoning proof checks of "Proofs".
Exits with status zero only if the velocity sanity check, the pointwise bound
check, and every property and proof check pass.
-}
module Main (main) where

import FFunction (powerLaw, reweight, ffLabel, evalF, normFTrunc, convFTrunc)
import Ising (coneAtTime, frontPosition, fitVelocity)
import Properties (runAllProperties)
import Proofs (runAllProofs, analyticUpperBoundTFIM, tfimFnormAt)
import Control.Monad (forM_)
import Text.Printf (printf)
import System.Exit (exitFailure, exitSuccess)

-- | Chain length (Hilbert-space dimension @2^chainLength@).
chainLength :: Int
chainLength = 7

-- | Ising couplings for the demonstration.
couplingJ, fieldH :: Double
couplingJ = 1.0
fieldH    = 1.0

-- | Times at which the light cone is sampled.
times :: [Double]
times = [0.3, 0.6, 0.9, 1.2, 1.5, 1.8]

main :: IO ()
main = do
  putStrLn "=== Condensed Locality (Paper I): the Lieb-Robinson light cone ==="
  putStrLn ""
  demoFFunctions
  putStrLn ""
  vok <- demoLightCone
  putStrLn ""
  pok <- runAllProperties
  putStrLn ""
  qok <- runAllProofs
  putStrLn ""
  if vok && pok && qok
    then putStrLn "All checks passed." >> exitSuccess
    else putStrLn "CHECKS FAILED." >> exitFailure

-- | Print the F-function constants and the reweighting inequalities of Lemma 2.3.
demoFFunctions :: IO ()
demoFFunctions = do
  putStrLn "--- F-functions and reweighting (Section 2) ---"
  let f  = powerLaw 1 0.5
      fa = reweight 0.5 f
  printf "  %s\n" (ffLabel f)
  printf "  ||F||    (truncated, R=300) = %8.4f\n" (normFTrunc 300 f)
  printf "  C_F      (truncated)        = %8.4f\n" (convFTrunc 300 f)
  printf "  ||F_a||  (a = 0.5)          = %8.4f   (Lemma 2.3: <= ||F||)\n" (normFTrunc 300 fa)
  printf "  C_{F_a}  (a = 0.5)          = %8.4f   (Lemma 2.3: <= C_F)\n" (convFTrunc 300 fa)

-- | Print the commutator-norm cone, fit a front velocity, and check both the pointwise
-- Lieb-Robinson bound of Theorem 3.1 (on disjoint supports, so @x >= 1@ only: at @x = 0@,
-- @X = Y = {0}@ are not disjoint and the theorem does not apply there) and the light-cone
-- velocity bound of Proposition 3.2, optimized over the reweighting parameter (Section 8).
demoLightCone :: IO Bool
demoLightCone = do
  putStrLn "--- Commutator norm c(x,t) = || [sigma^x_0(t), sigma^x_x] || (Section 8) ---"
  printf "  chain N = %d,  J = %.2f,  h = %.2f\n" chainLength couplingJ fieldH
  putStr "     t \\ x |"
  forM_ [0 .. chainLength - 1] (printf " %5d")
  putStrLn ""
  putStrLn ("    -------+" ++ concat (replicate chainLength "------"))
  results <- mapM printRow times
  let rows      = map fst results
      lrBoundOK = and (map snd results)
      vfit      = fitVelocity rows
      vphys     = 2 * min couplingJ fieldH
      vup       = analyticUpperBoundTFIM couplingJ fieldH
  printf "  fitted front velocity  v_fit  = %.3f  (sites / time)\n" vfit
  printf "  free-fermion max group v_phys = %.3f  = 2 min(J,h)\n" vphys
  printf "  analytic LR upper bound v_up  = %.3f  = min_a 2||Phi||_Fa C_Fa/a (Prop 3.2)\n" vup
  let velOK = vfit >= 0 && vfit <= vup
  putStrLn ("  velocity sanity    0 <= v_fit <= v_up          : " ++ (if velOK then "OK" else "FAIL"))
  putStrLn ("  Thm 3.1 pointwise LR bound (disjoint supports) : " ++ (if lrBoundOK then "OK" else "FAIL"))
  return (velOK && lrBoundOK)
  where
    -- Reference F-function for the Theorem 3.1 pointwise check: the same power-law weight
    -- used throughout the F-function demo above.
    referenceF = powerLaw 1 0.5
    -- Theorem 3.1 [thm:lr-bound], pointwise, for the actual simulated row: for disjoint
    -- single-site supports X={0}, Y={x} (x >= 1, so dist(X,Y) = x) with ||A|| = ||B|| = 1
    -- (Example 3.6 / proof_operatorNormsUnit), the bound reads
    --   c(x,t) <= (2 / C_F) * (e^{2 ||Phi||_F C_F |t|} - 1) * F(x).
    checkLRBoundPointwise :: Double -> [(Int, Double)] -> Bool
    checkLRBoundPointwise t row =
      let cF = convFTrunc 300 referenceF
          bF = tfimFnormAt couplingJ fieldH referenceF
      in and [ c <= (2 / cF) * (exp (2 * bF * cF * t) - 1) * evalF referenceF (fromIntegral x) + 1e-9
             | (x, c) <- row, x >= 1 ]
    printRow :: Double -> IO ((Double, Int), Bool)
    printRow t = do
      let row = coneAtTime chainLength couplingJ fieldH t
      printf "    %5.2f  |" t
      forM_ row (\(_, c) -> printf " %5.2f" c)
      putStrLn ""
      -- x = 0 is excluded from the front-position fit: X = Y = {0} there are not disjoint
      -- supports, so Theorem 3.1's light-cone estimate does not apply to that column at all.
      let frontRow = filter (\(x, _) -> x >= 1) row
      return ((t, frontPosition 0.1 frontRow), checkLRBoundPointwise t row)
