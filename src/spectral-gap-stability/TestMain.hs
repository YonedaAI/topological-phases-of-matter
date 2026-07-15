{-|
Module      : TestMain
Description : cabal-test entry point: runs the verification suites only.
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Entry point for @cabal test@: runs the QuickCheck property suite ("Properties") and
the deterministic theorem-instance suite ("Proofs") and exits non-zero if either
fails, without the demo output ("Main"'s gap table, critical-point trend, and
perturbation experiment) -- so the test run is a plain pass/fail check rather than a
repeat of the demo. @cabal run sgs-demo@ remains the full demonstration described in
Section 8.5 of the paper, exiting on the same two suites.
-}
module Main (main) where

import System.Exit (exitFailure, exitSuccess)

import Properties (runAllProperties)
import Proofs (runAllInstances)

main :: IO ()
main = do
  okProperties <- runAllProperties
  putStrLn ""
  okInstances <- runAllInstances
  putStrLn ""
  if okProperties && okInstances
    then putStrLn "All verifications passed." >> exitSuccess
    else putStrLn "VERIFICATION FAILURES DETECTED." >> exitFailure
