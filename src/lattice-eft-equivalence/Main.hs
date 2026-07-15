{-|
Module      : Main
Description : Demonstrations for Part IV: group completion of stacking monoids
              and the tenfold-way periodic table.
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Runs the constructive content of "From Lattice Models to Effective Field
Theories".  It computes the Grothendieck group completion of three monoids --
the free monoid on one generator (completing to @Z@), the free monoid on two
generators (completing to @Z^2@), and the non-cancellative toy monoid
@<a,t | t+a=t>@ of Example 4.5, where @a@ collapses to @0@ while the powers of
@t@ stay distinct, so the completion is @Z@ (not @0@) -- and prints Table 1, the
tenfold-way periodic table.  It exits with status 0.
-}
module Main (main) where

import qualified Data.Map.Strict as Map
import Monoid
import TenfoldWay (renderTable)

main :: IO ()
main = do
  putStrLn "=== Part IV: Stabilization and the Invertible Condensed Phase Spectrum ==="
  putStrLn ""

  putStrLn "--- Demonstration 1: group completion of the free monoid N (one generator) ---"
  let free1 = freeCMonoid ["a"]
      a     = gen "a"
  mapM_ (putStrLn . describeCompletion free1) [zero, a, scale 2 a, scale 3 a]
  putStrLn "  K(N) = Z: gamma is injective (the monoid is cancellative), no collapse."
  putStrLn ""

  putStrLn "--- Demonstration 2: group completion of N^2 (two generators) ---"
  let free2 = freeCMonoid ["a", "b"]
      b     = gen "b"
      x     = plus (scale 2 a) b     -- 2a + b
      y     = plus a (scale 2 b)     -- a + 2b
  mapM_ (putStrLn . describeCompletion free2) [x, y]
  putStrLn ("  2a+b and a+2b differ in K(N^2)=Z^2?  "
            ++ show (not (eqG free2 (gamma x) (gamma y))))
  putStrLn ""

  putStrLn "--- Demonstration 3: the non-cancellative toy monoid <a,t | t+a=t> ---"
  let t = gen "t"
  putStrLn ("  monoid: " ++ cName toyMonoid)
  putStrLn ("  normal form of a+t : " ++ show (normalise toyMonoid (plus a t))
            ++ "   (equals normal form of t : " ++ show (normalise toyMonoid t) ++ ")")
  mapM_ (putStrLn . describeCompletion toyMonoid) [zero, a, t, plus a t, scale 2 t]
  putStrLn ("  a is nonzero on the nose (nf a = " ++ show (normalise toyMonoid a)
            ++ ") but gamma a = gamma 0 via the witness e = t:")
  putStrLn ("    a + t = " ++ show (normalise toyMonoid (plus a t))
            ++ "  and  0 + t = " ++ show (normalise toyMonoid t))
  putStrLn ("  K(M) collapses a to 0?              " ++ show (isTrivialG toyMonoid (gamma a)))
  putStrLn ("  but t survives (gamma t nontrivial)? " ++ show (not (isTrivialG toyMonoid (gamma t))))
  let tMul n     = scale n t
      distinctT  = and [ not (eqG toyMonoid (gamma (tMul i)) (gamma (tMul j)))
                       | i <- [1..4], j <- [1..4], i /= j ]
  putStrLn ("  multiples t, 2t, 3t, 4t pairwise distinct in K(M)? " ++ show distinctT)
  putStrLn "  => a collapses but t generates a free Z, so K(M) = Z (not 0)."
  putStrLn ""

  putStrLn "--- Demonstration 4: universal property (Theorem 4.2(iii)) ---"
  putStrLn "  f : N -> Z, a |-> 3, extended additively; induced fbar on K(N) recovers f."
  let f  = weightHom (Map.fromList [("a", 3)])
      ok = all (\e -> induced f (gamma e) == f e) [zero, a, scale 4 a]
  putStrLn ("  fbar . gamma == f on samples?  " ++ show ok)
  putStrLn ""

  putStrLn "--- Table 1: the tenfold-way periodic table (regenerated) ---"
  putStr renderTable
  putStrLn ("  real classes: 8-periodic in d; complex classes: 2-periodic in d;"
            ++ "\n  every entry constant along antidiagonals s - d = const.")
  putStrLn ""

  putStrLn "All demonstrations completed successfully."
