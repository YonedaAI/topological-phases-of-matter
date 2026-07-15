{-|
Module      : Properties
Description : QuickCheck properties for the Part V propositions
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

QuickCheck properties, one per claim of the two elementary propositions of
Part V: quantization of the Kitaev-chain Z2 invariant and its jump on the
discriminant (Proposition "Kitaev-chain Z2 invariant", bordism-realizability.tex:634-663),
and the cluster-state SPT string order together with its degradation under a
symmetry-breaking rotation (Proposition "Cluster-state string order",
bordism-realizability.tex:493-537).

Every generator below constructs its values only through the domain-validating
smart constructors of "Kitaev" ('mkGapped') and "Stabilizer" ('mkStringWindow'),
so a generated 'GappedKitaevParams' or 'ValidWindow' is guaranteed valid by
construction rather than by a separate, possibly-incomplete filter; two
properties ('prop_mkGappedRejectsOutOfDomain', 'prop_mkStringWindowRejectsInvalid')
additionally check that the smart constructors reject out-of-domain input.
-}
module Properties
  ( runAllProperties
  ) where

import Data.Maybe (isJust)
import Test.QuickCheck
import Kitaev
import Stabilizer

-- | A Kitaev-chain parameter point known to satisfy Prop. kitaev's domain
--   (@Delta_p /= 0@, off the discriminant @|mu| = 2|t|@), built only via
--   'mkGapped'. Covers both signs of @t@ and @Delta_p@ (the physics is
--   sign-symmetric in each). Wrapped in a local newtype so the 'Arbitrary'
--   instance is not an orphan (both the class and 'GappedKitaevParams' are
--   defined elsewhere).
newtype ArbGapped = ArbGapped GappedKitaevParams
  deriving Show

instance Arbitrary ArbGapped where
  arbitrary = do
    t   <- choose (-2.5, 2.5) `suchThat` (\x -> abs x > 0.3)
    del <- choose (-2.0, 2.0) `suchThat` (\x -> abs x > 0.3)
    mu  <- choose (-6.0, 6.0) `suchThat` (\m -> abs (abs m - 2 * abs t) > 0.15)
    case mkGapped (KitaevParams mu t del) of
      Just gp -> return (ArbGapped gp)
      Nothing -> arbitrary  -- retry; the choose/suchThat bounds above should already avoid this

-- | A pair of positive @(t, Delta)@ values for boundary-detection tests. @t@
--   ranges well past the old fixed scan ceiling (formerly hard-coded to
--   @mu <= 4@ in 'detectBoundary', silently wrong for @|t| > 2@) to exercise
--   the dynamic bracketing around @2|t|@.
newtype PosPair = PosPair (Double, Double)
  deriving Show

instance Arbitrary PosPair where
  arbitrary = do
    t   <- choose (0.1, 8.0)
    del <- choose (0.1, 3.0)
    return (PosPair (t, del))

-- | A valid cluster-state string window, built only via 'mkStringWindow'.
--   Slack on both sides of the window varies (including zero), so generated
--   windows are sometimes boundary-adjacent (@a = 0@ and/or @b = n-1@) rather
--   than always leaving fixed room to spare.
newtype ValidWindow = ValidWindow StringWindow
  deriving Show

instance Arbitrary ValidWindow where
  arbitrary = do
    m      <- choose (1, 5)   -- number of X-factors
    a      <- choose (0, 4)   -- slack before a
    slackR <- choose (0, 4)   -- slack after b; 0 makes b = n-1 (boundary-adjacent)
    let b = a + 2 * m
        n = b + 1 + slackR
    case mkStringWindow n a b of
      Just w  -> return (ValidWindow w)
      Nothing -> arbitrary  -- retry; the construction above is always valid by design

-- Proposition (Kitaev-chain Z2 invariant) ----------------------------------

-- | The winding number is @0@ or @1@ on the gapped locus and equals @(1 - M)/2@.
prop_windingQuantized :: ArbGapped -> Bool
prop_windingQuantized (ArbGapped gp) =
  w `elem` [0, 1] && w == (1 - m) `div` 2
  where
    w = windingNumberG gp
    m = majoranaNumberG gp

-- | The chain is topological (winding @1@) exactly when @|mu| < 2|t|@.
prop_boundaryMatchesTheory :: ArbGapped -> Bool
prop_boundaryMatchesTheory (ArbGapped gp) =
  (windingNumberG gp == 1) == (abs (kpMu p) < 2 * abs (kpT p))
  where p = unGapped gp

-- | 'mkGapped' rejects points outside Prop. kitaev's domain: @Delta_p = 0@
--   (for any @mu@, @t@ -- including well inside @|mu| < 2|t|@, the gapless
--   normal-metal locus that a discriminant-only check would miss) and exactly
--   on the discriminant @mu = 2t@.
prop_mkGappedRejectsOutOfDomain :: Property
prop_mkGappedRejectsOutOfDomain =
  forAll (choose (-4.0, 4.0)) $ \mu ->
  forAll (choose (-2.0, 2.0) `suchThat` (\x -> abs x > 0.2)) $ \t ->
       not (isJust (mkGapped (KitaevParams mu t 0)))
    && not (isJust (mkGapped (KitaevParams (2 * t) t 1.0)))

-- | The invariant-detected boundary matches the analytic value @2t@.
prop_detectBoundary :: PosPair -> Bool
prop_detectBoundary (PosPair (t, del)) =
  case detectBoundary t del of
    Just b  -> abs (b - planeBoundary t) < 0.05
    Nothing -> False

-- | 'detectBoundary' rejects @Delta_p ~= 0@ (outside Prop. kitaev's domain,
--   so there is no topological transition to find).
prop_detectBoundaryRejectsZeroDelta :: Property
prop_detectBoundaryRejectsZeroDelta =
  forAll (choose (-5.0, 5.0)) $ \t -> detectBoundary t 0 == Nothing

-- Proposition (Cluster-state string order) ---------------------------------

-- | The cluster-state string order parameter is exactly @+1@.
prop_stringOrderOne :: ValidWindow -> Bool
prop_stringOrderOne (ValidWindow w) = stringOrder w == 1

-- | No local order: every single-site expectation vanishes, not merely at one
--   distinguished site (bordism-realizability.tex:500-501: "every single-site
--   expectation vanishes, @<Z_j> = <X_j> = 0@").
prop_noLocalOrder :: ValidWindow -> Bool
prop_noLocalOrder (ValidWindow w) =
  all (\j -> expectation gens (single n LZ j) == 0
          && expectation gens (single n LX j) == 0)
      [0 .. n - 1]
  where
    n    = swN w
    gens = clusterGenerators n

-- | Under the symmetry-breaking rotation the string order equals @cos(theta)^m@.
prop_stringDegradation :: ValidWindow -> Property
prop_stringDegradation (ValidWindow w) =
  forAll (choose (0, pi / 2)) $ \theta ->
    abs (stringOrderRotated w theta - cos theta ^ numX w) < 1e-9

-- | The degraded string order is monotone decreasing in @theta@ on @[0, pi/2]@.
prop_stringMonotone :: ValidWindow -> Property
prop_stringMonotone (ValidWindow w) =
  forAll (choose (0, pi / 2 - 0.01)) $ \theta ->
    stringOrderRotated w theta
      >= stringOrderRotated w (theta + 0.01) - 1e-9

-- | 'mkStringWindow' accepts a window iff @0 <= a < b <= n-1@ and @b - a@ is
--   even, matching the paper's precondition exactly
--   (bordism-realizability.tex:493-497: "fix a<b with b-a even").
prop_mkStringWindowRejectsInvalid :: Property
prop_mkStringWindowRejectsInvalid =
  forAll (choose (2, 12)) $ \n ->
  forAll (choose (0, 12)) $ \a ->
  forAll (choose (0, 12)) $ \b ->
    let valid = 0 <= a && a < b && b <= n - 1 && even (b - a)
    in isJust (mkStringWindow n a b) == valid

-- Runner -------------------------------------------------------------------

-- | Run every property; print a per-property pass/fail line; return overall success.
runAllProperties :: IO Bool
runAllProperties = do
  putStrLn "=== QuickCheck Property Verification ==="
  results <- sequence
    [ check "Prop (Kitaev): winding quantized, w = (1-M)/2" (property prop_windingQuantized)
    , check "Prop (Kitaev): winding=1 iff |mu| < 2|t|"      (property prop_boundaryMatchesTheory)
    , check "Prop (Kitaev): mkGapped rejects out-of-domain" prop_mkGappedRejectsOutOfDomain
    , check "Prop (Kitaev): detected boundary matches 2t"   (property prop_detectBoundary)
    , check "Prop (Kitaev): detectBoundary rejects Delta=0" prop_detectBoundaryRejectsZeroDelta
    , check "Prop (cluster): string order = +1"             (property prop_stringOrderOne)
    , check "Prop (cluster): no local order (<Z>=<X>=0), all sites" (property prop_noLocalOrder)
    , check "Prop (cluster): degradation = cos^m theta"     (property prop_stringDegradation)
    , check "Prop (cluster): string order monotone"         (property prop_stringMonotone)
    , check "Prop (cluster): mkStringWindow rejects invalid windows" prop_mkStringWindowRejectsInvalid
    ]
  let passed = length (filter id results)
      nTotal = length results
  putStrLn (show passed ++ "/" ++ show nTotal ++ " properties passed")
  return (and results)
  where
    check :: String -> Property -> IO Bool
    check name prop = do
      putStr ("  " ++ name ++ " ... ")
      r <- quickCheckResult prop
      case r of
        Success{} -> putStrLn "OK" >> return True
        _         -> putStrLn "FAILED" >> return False
