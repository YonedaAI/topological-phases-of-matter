{-|
Module      : Main (test-suite entry point)
Description : Lightweight test-suite driver for Paper I's Haskell companion code.
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

The test-suite's own entry point, separate from the demo executable's (Main.hs / @lr-demo@):
runs only the QuickCheck properties ("Properties") and the equational-reasoning proof checks
("Proofs"), without the F-function/TFIM simulation demo that @lr-demo@ also prints.
-}
module Main (main) where

import Properties (runAllProperties)
import Proofs (runAllProofs)
import System.Exit (exitFailure, exitSuccess)

main :: IO ()
main = do
  pok <- runAllProperties
  putStrLn ""
  qok <- runAllProofs
  putStrLn ""
  if pok && qok
    then putStrLn "All checks passed." >> exitSuccess
    else putStrLn "CHECKS FAILED." >> exitFailure
