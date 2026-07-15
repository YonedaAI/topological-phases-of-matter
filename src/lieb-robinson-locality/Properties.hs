{-|
Module      : Properties
Description : QuickCheck properties for the F-function calculus of Paper I.
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Randomized checks of the elementary claims of "Condensed Locality": F-functions
are non-increasing (Definition 2.2), the exponential reweighting decreases the
weight pointwise and cannot increase the summability constant (Lemma 2.3), the
sup-of-ratios construction underlying the F-norm is subadditive (the mechanism
of Proposition 2.6, "BF is a Banach space"; Definition 2.5 is the F-norm
itself, and 'prop_tfimFnormRandom' below tests it on an actual interaction),
and the analytic Lieb-Robinson velocity is positive and monotone in the norm
bound (Proposition 3.2).
-}
module Properties
  ( runAllProperties
  ) where

import Test.QuickCheck
  ( Testable, Property, Args(..), Result
  , NonNegative(..), Positive(..)
  , quickCheckWithResult, stdArgs, isSuccess, (==>)
  )
import FFunction
  ( powerLaw, exponential, reweight, evalF, normFTrunc, convFTruncAt
  , analyticVelocity )

-- | Definition 2.2: a power-law F-function is non-increasing.
prop_decayMonotone :: NonNegative Double -> NonNegative Double -> Bool
prop_decayMonotone (NonNegative r1) (NonNegative r2) =
  let f       = powerLaw 1 0.5
      (lo, hi) = (min r1 r2, max r1 r2)
  in evalF f lo + 1e-12 >= evalF f hi

-- | Definition 2.2: an exponential F-function is non-increasing.
prop_expMonotone :: NonNegative Double -> NonNegative Double -> Bool
prop_expMonotone (NonNegative r1) (NonNegative r2) =
  let f       = exponential 0.7
      (lo, hi) = (min r1 r2, max r1 r2)
  in evalF f lo + 1e-12 >= evalF f hi

-- | Lemma 2.3: reweighting decreases the weight pointwise, @F_a(r) <= F(r)@.
prop_reweightPointwise :: NonNegative Double -> NonNegative Double -> Bool
prop_reweightPointwise (NonNegative a) (NonNegative r) =
  let f = powerLaw 2 0.3
  in evalF (reweight a f) r <= evalF f r + 1e-12

-- | Lemma 2.3 (summability side): truncated @||F_a|| <= ||F||@.
prop_reweightNorm :: NonNegative Double -> Bool
prop_reweightNorm (NonNegative a) =
  let f = powerLaw 1 0.5
  in normFTrunc 200 (reweight a f) <= normFTrunc 200 f + 1e-9

-- | Lemma 2.3 (convolution side): truncated @C_{F_a} <= C_F@, checked as a supremum over a
-- bounded set of separations @m@ rather than only @m = 1@, since Definition 2.2's @C_F@ is
-- itself a supremum over all base-point pairs, not a single fixed separation.
prop_reweightConv :: NonNegative Double -> Bool
prop_reweightConv (NonNegative a) =
  let f  = powerLaw 1 0.5
      ms = [1, 2, 3, 5, 8, 13, 21]
      supAt g = maximum [ convFTruncAt 200 m g | m <- ms ]
  in supAt (reweight a f) <= supAt f + 1e-9

-- | The mechanism behind Proposition 2.6 ("BF is a Banach space"): the sup-of-ratios
-- @sup_i a_i/w_i@ that the F-norm of Definition 2.5 is built from is subadditive,
-- @sup_i (a_i + b_i)/w_i <= sup_i a_i/w_i + sup_i b_i/w_i@. This is an algebraic helper
-- lemma about lists of ratios, not yet a statement about interactions, supports, or operator
-- norms; 'prop_tfimFnormRandom' below tests the actual Definition 2.5 F-norm on an
-- interaction.
prop_fnormSubadditive
  :: [Positive Double] -> [Positive Double] -> [Positive Double] -> Property
prop_fnormSubadditive as bs ws =
  let n = minimum [length as, length bs, length ws]
  in n >= 1 ==>
       let a = take n (map getPositive as)
           b = take n (map getPositive bs)
           w = take n (map getPositive ws)
           supRatio xs = maximum (zipWith (/) xs w)
       in supRatio (zipWith (+) a b) <= supRatio a + supRatio b + 1e-9

-- | Definition 2.5 (interaction and F-norm), on the transverse-field Ising interaction of
-- Example 3.6: for random couplings @J, h > 0@ on a 9-site chain, the F-norm computed
-- directly from the interaction's finite support list (singles of weight @h@, bonds of
-- weight @J@) — i.e. @sup_{x,y} F(dist(x,y))^{-1} sum_{X ni x,y} ||Phi(X)||@, Definition 2.5's
-- own formula, with Pauli tensor products having operator norm 1 so @||Phi(X)|| = @ the
-- coefficient's absolute value — matches the closed form
-- @max{(h+2J)/F(0), J/F(1)}@ that Example 3.6 derives.
prop_tfimFnormRandom :: Positive Double -> Positive Double -> Bool
prop_tfimFnormRandom (Positive jj) (Positive hh) =
  let f = powerLaw 1 0.5
      n = 9 :: Int
      singles = [ ([k], hh)       | k <- [0 .. n - 1] ]
      bonds   = [ ([k, k + 1], jj) | k <- [0 .. n - 2] ]
      terms   = singles ++ bonds
      weight x y = sum [ w | (supp, w) <- terms, x `elem` supp, y `elem` supp ]
      ratio x y  = weight x y / evalF f (fromIntegral (abs (x - y)))
      computed   = maximum [ ratio x y | x <- [0 .. n - 1], y <- [0 .. n - 1] ]
      closedForm = max ((hh + 2 * jj) / evalF f 0) (jj / evalF f 1)
  in abs (computed - closedForm) < 1e-9

-- | Proposition 3.2: the analytic velocity is positive and increases with the
-- uniform norm bound @B_a@.
prop_velocityMonotone
  :: Positive Double -> Positive Double -> Positive Double -> Positive Double -> Bool
prop_velocityMonotone (Positive b1) (Positive db) (Positive c) (Positive a) =
  let b2 = b1 + db
      v1 = analyticVelocity b1 c a
      v2 = analyticVelocity b2 c a
  in v1 > 0 && v2 >= v1

-- | Run every property, printing a compact pass/fail line for each.
runAllProperties :: IO Bool
runAllProperties = do
  putStrLn "=== QuickCheck property verification ==="
  results <- sequence
    [ chk "Def 2.2  decay monotone (power law)"     prop_decayMonotone
    , chk "Def 2.2  decay monotone (exponential)"   prop_expMonotone
    , chk "Lemma 2.3 reweight pointwise"             prop_reweightPointwise
    , chk "Lemma 2.3 reweight norm bound"             prop_reweightNorm
    , chk "Lemma 2.3 reweight conv bound (sup over m)" prop_reweightConv
    , chk "Prop 2.6  sup-of-ratios subadditivity"     prop_fnormSubadditive
    , chk "Def 2.5   TFIM F-norm (Example 3.6)"       prop_tfimFnormRandom
    , chk "Prop 3.2  velocity positive/monotone"      prop_velocityMonotone
    ]
  let passed = length (filter id results)
      total  = length results
  putStrLn ("  " ++ show passed ++ "/" ++ show total ++ " properties passed")
  return (and results)
  where
    chk :: Testable p => String -> p -> IO Bool
    chk name prop = do
      res <- quickCheckWithResult stdArgs { chatty = False } prop
      let ok = isSuccess (res :: Result)
      putStrLn ("  " ++ (if ok then "[OK]  " else "[FAIL] ") ++ name)
      return ok
