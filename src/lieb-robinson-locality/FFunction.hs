{-|
Module      : FFunction
Description : F-functions and locality weights for Lieb-Robinson bounds (Paper I).
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Implements the Nachtergaele-Sims-Young F-function apparatus of Section 2 of
"Condensed Locality": power-law and exponential decay, the exponential
reweighting F_a(r) = exp(-a r) F(r) of Lemma 2.3, truncated estimates of the
summability constant ||F|| and the convolution constant C_F on the line, and the
analytic Lieb-Robinson velocity v = 2 ||Phi||_{F_a} C_{F_a} / a of Proposition 3.2.

'FFunction' is exported opaquely: the paper's Definition 2.2 requires a positive,
non-increasing function with a strictly positive decay rate, and the smart constructors
below ('powerLaw', 'exponential', 'reweight') clamp out-of-range parameters (@eps <= 0@,
@theta <= 0@, @a < 0@) up to the nearest valid value rather than silently building a
function that fails those axioms.
-}
module FFunction
  ( -- * Type
    FFunction
    -- * Constructors and combinators
  , powerLaw
  , exponential
  , reweight
    -- * Evaluation and constants
  , evalF
  , ffLabel
  , normFTrunc
  , convFTrunc
  , convFTruncAt
  , analyticVelocity
  ) where

-- | An F-function: a non-increasing positive weight on distances, plus a label. The data
-- constructor is not exported; build values only via 'powerLaw', 'exponential', or
-- 'reweight', each of which validates its parameters against Definition 2.2.
data FFunction = FFunction
  { ffDecay :: Double -> Double  -- ^ the weight @r |-> F(r)@
  , ffLabel :: String            -- ^ human-readable description
  }

-- | Power-law F-function on @Z^d@: @F(r) = (1+r)^{-(d+epsilon)}@ (Lemma 2.4). Definition 2.2
-- needs @eps > 0@ for uniform summability and @d >= 0@; a non-positive @eps@ is clamped up to
-- a small positive floor and a negative @d@ is clamped to @0@, rather than silently accepted.
powerLaw :: Int -> Double -> FFunction
powerLaw d0 eps0 = FFunction
  { ffDecay = \r -> (1 + r) ** negate (fromIntegral d + eps)
  , ffLabel = "power-law (1+r)^-(d+eps), d=" ++ show d ++ ", eps=" ++ show eps
  }
  where
    d   = max 0 d0
    eps = if eps0 > 0 then eps0 else 1e-6

-- | Exponential F-function: @F(r) = e^{-theta r}@. Requires @theta > 0@ for genuine decay; a
-- non-positive @theta@ is clamped up to a small positive floor.
exponential :: Double -> FFunction
exponential theta0 = FFunction
  { ffDecay = \r -> exp (negate theta * r)
  , ffLabel = "exponential e^-(theta r), theta=" ++ show theta
  }
  where
    theta = if theta0 > 0 then theta0 else 1e-6

-- | Exponential reweighting @F_a(r) = e^{-a r} F(r)@ (Lemma 2.3). Lemma 2.3's inequalities
-- are stated for @a >= 0@; a negative @a@ is clamped to @0@ (the identity reweighting) rather
-- than silently accepted.
reweight :: Double -> FFunction -> FFunction
reweight a0 f = FFunction
  { ffDecay = \r -> exp (negate a * r) * ffDecay f r
  , ffLabel = "reweight(a=" ++ show a ++ ") of " ++ ffLabel f
  }
  where
    a = max 0 a0

-- | Evaluate an F-function at a distance.
evalF :: FFunction -> Double -> Double
evalF = ffDecay

-- | Truncated summability constant on the 1D lattice @Z@ with @R@ shells:
-- @||F|| ~ F(0) + 2 * sum_{n=1}^R F(n)@ (two sites at each distance @n@ on @Z@).
normFTrunc :: Int -> FFunction -> Double
normFTrunc rr f = evalF f 0 + 2 * sum [ evalF f (fromIntegral n) | n <- [1 .. rr] ]

-- | Truncated convolution constant @C_F@ on @Z@ at a chosen separation @m@ (Definition 2.2's
-- axiom (F2), which is itself a supremum over all base-point pairs, not just @m = 1@):
-- estimates @sum_z F(|z|) F(|z-m|) / F(m)@ over @|z| <= R@. 'convFTrunc' is the @m = 1@ case.
convFTruncAt :: Int -> Int -> FFunction -> Double
convFTruncAt rr m f =
  let contrib z = evalF f (fromIntegral (abs z)) * evalF f (fromIntegral (abs (z - m)))
      total = sum [ contrib z | z <- [negate rr .. rr] ]
  in total / evalF f (fromIntegral m)

-- | Truncated convolution constant @C_F@ on @Z@ for the pair at separation 1:
-- estimates @sum_z F(|z|) F(|z-1|) / F(1)@ over @|z| <= R@.
convFTrunc :: Int -> FFunction -> Double
convFTrunc rr = convFTruncAt rr 1

-- | Analytic Lieb-Robinson velocity @v = 2 B_a C_{F_a} / a@ (Proposition 3.2),
-- for a uniform norm bound @B_a@, convolution constant @C_{F_a}@, and rate @a@.
analyticVelocity :: Double -> Double -> Double -> Double
analyticVelocity bA cFa a = 2 * bA * cFa / a
