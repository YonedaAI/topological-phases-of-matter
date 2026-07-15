{-|
Module      : Proofs
Description : Deterministic examples and finite exhaustive checks for the paper's two propositions (Part V, Sec. V-A)
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Concrete, non-randomized checks of the identities behind the two elementary
propositions of Part V, on fixed parameter points and fixed or exhaustively
enumerated stabilizer instances. These are worked examples and finite
exhaustive checks, not a machine proof of the universally-quantified
propositions themselves (which are proved on paper); where 'Properties'
samples at random over an infinite domain, this module either pins down
specific values so the arithmetic can be read off and audited, or enumerates
every instance of a finite sub-domain (every valid window / every interior
site / a fixed fine grid of angles for a given chain length) so the check is
complete for that sub-domain rather than a handful of examples:

  * Proposition (Kitaev-chain Z2 invariant), bordism-realizability.tex:634-663:
    the closed form @d_z(0) = -2t - mu@, @d_z(pi) = 2t - mu@ (compared to
    'dVector' within tolerance, not by exact @Double@ equality -- @dVector@
    evaluates @cos@/@sin@ at @0@ and @pi@, and this module does not assume a
    particular libm rounds those to bit-exact @1@/@-1@/@0@), hence
    @M = sgn(d_z(0)) sgn(d_z(pi)) = sgn(mu^2 - 4t^2)@, and the exact sign flip
    of @M@ across the discriminant @|mu| = 2|t|@: at fixed @t = 1@, @M@ takes
    the values @-1, 0, +1@ at @mu = 1.9, 2.0, 2.1@. This flip check is itself
    algebraic, not a floating-point coincidence: 'majoranaNumber' computes
    @d_z(0)@, @d_z(pi)@ from the closed form directly (no trigonometric call),
    so @M(2.0) = 0@ because @2*1 - 2 = 0@ exactly, on any platform.
  * Proposition (Cluster-state string order), bordism-realizability.tex:493-537:
    the telescoping identity @K_{a+1} K_{a+3} ... K_{b-1} = S_{a,b}@ that places
    the string operator inside the stabilizer group (checked as exact equality
    of the 'Pauli' record, i.e. same X/Z pattern *and* the same overall phase,
    not just up to sign) and the string-order value @+1@, both checked over
    *every* valid window of two chain lengths (bordism-realizability.tex:493-497
    for the window precondition, :512-526 for the telescoping proof); the
    anticommutation bookkeeping that is the load-bearing detail behind
    @<Z_j> = <X_j> = 0@ (@Z_j@ anticommutes with @K_j@ through their shared
    central @X_j@; @X_j@ anticommutes with the flanking generators @K_{j-1}@
    and @K_{j+1}@ through their @Z_j@ factors, but commutes with its own
    @K_j@ -- bordism-realizability.tex:526-529), checked over every interior
    site of two chain lengths; and the @cos^m(theta)@ degradation
    (bordism-realizability.tex:529-537), checked to five decimal places over a
    21-point grid spanning @[0, pi/2]@.
-}
module Proofs
  ( runAllProofs
  ) where

import Kitaev
import Stabilizer

-- | A single named check with a boolean outcome.
data Check = Check
  { checkName :: String
  , checkOk   :: Bool
  }

-- | Build a 'StringWindow' from literal, hand-verified @(n, a, b)@; raises a
--   clear error (rather than silently misbehaving) if a literal used below is
--   ever mistyped into an invalid window.
mkWindowOrError :: Int -> Int -> Int -> StringWindow
mkWindowOrError n a b = case mkStringWindow n a b of
  Just w  -> w
  Nothing -> error ("Proofs: invalid window literal n=" ++ show n
                     ++ " a=" ++ show a ++ " b=" ++ show b)

-- | Every valid window 'mkStringWindow' accepts for a fixed @n@: @0 <= a < b
--   <= n-1@, @b-a@ even.
allWindows :: Int -> [StringWindow]
allWindows n =
  [ w | a <- [0 .. n - 1], b <- [0 .. n - 1], Just w <- [mkStringWindow n a b] ]

-- Prop (Kitaev-chain Z2 invariant) -----------------------------------------

-- | @d_z(0) = -2t - mu@ and @d_z(pi) = 2t - mu@ at a fixed parameter point,
--   checked against 'dVector' to within tolerance. This does not use exact
--   @Double@ equality: 'dVector' evaluates @cos@/@sin@ at @0@ and @pi@, and
--   this check does not assume a particular libm rounds those bit-exactly to
--   @1@/@-1@/@0@ (unlike 'majoranaNumber' itself, which sidesteps the
--   question entirely by using the closed form).
dzEndpointsCheck :: String -> KitaevParams -> Check
dzEndpointsCheck lbl p@(KitaevParams mu t _) = Check
  { checkName = "d_z(0), d_z(pi) match closed form -2t-mu, 2t-mu (tol 1e-9) " ++ lbl
  , checkOk   =    abs (snd (dVector p 0)  - (negate (2 * t) - mu)) < 1e-9
                && abs (snd (dVector p pi) - (2 * t - mu))          < 1e-9
  }

-- | The Majorana number equals the closed form @sgn(mu^2 - 4t^2)@ at a fixed
--   point, away from the discriminant.
majoranaClosedFormCheck :: String -> KitaevParams -> Check
majoranaClosedFormCheck lbl p@(KitaevParams mu t _) = Check
  { checkName = "Majorana number = sgn(mu^2 - 4t^2) " ++ lbl
  , checkOk   = majoranaNumber p == round (signum (mu * mu - 4 * t * t))
  }

-- | The Majorana number flips @-1 -> 0 -> +1@ exactly at the discriminant
--   @|mu| = 2|t|@: at fixed @t = 1@, @M(1.9) = -1@ (topological),
--   @M(2.0) = 0@ (exactly on the gap closing), and @M(2.1) = +1@ (trivial).
--   The three-valued flip is forced by the closed form on any platform:
--   'majoranaNumber' computes @d_z(pi) = 2t - mu@ by subtraction alone (no
--   trigonometric evaluation), so @d_z(pi) = 0@ at @mu = 2t@ is exact
--   arithmetic, not a libm coincidence.
majoranaFlipCheck :: Check
majoranaFlipCheck = Check
  { checkName = "Majorana number flips -1 -> 0 -> +1 exactly at |mu| = 2|t|"
  , checkOk   =    majoranaNumber (KitaevParams 1.9 1.0 1.0) == -1
                && majoranaNumber (KitaevParams 2.0 1.0 1.0) ==  0
                && majoranaNumber (KitaevParams 2.1 1.0 1.0) ==  1
  }

-- | The winding number and Majorana number agree via @w = (1-M)/2@ at fixed
--   points on both sides of the discriminant.
windingMajoranaAgreeCheck :: String -> KitaevParams -> Check
windingMajoranaAgreeCheck lbl p = Check
  { checkName = "winding = (1-M)/2 " ++ lbl
  , checkOk   = windingNumber p == (1 - majoranaNumber p) `div` 2
  }

-- | 'isTopological' agrees with the sign of the Majorana number at fixed points.
topologicalAgreesWithMajoranaCheck :: String -> KitaevParams -> Bool -> Check
topologicalAgreesWithMajoranaCheck lbl p expected = Check
  { checkName = "isTopological matches (M == -1) " ++ lbl
  , checkOk   = isTopological p == expected && (majoranaNumber p == -1) == expected
  }

-- | 'mkGapped' rejects a fixed @Delta_p = 0@ point and a fixed on-discriminant
--   point, matching Prop. kitaev's domain (bordism-realizability.tex:634-636).
mkGappedRejectsCheck :: Check
mkGappedRejectsCheck = Check
  { checkName = "mkGapped rejects Delta=0 (mu=1,t=1) and on-discriminant (mu=2,t=1)"
  , checkOk   =    mkGapped (KitaevParams 1.0 1.0 0.0) == Nothing
                && mkGapped (KitaevParams 2.0 1.0 1.0) == Nothing
                && mkGapped (KitaevParams 1.9 1.0 1.0) /= Nothing
  }

-- | Being outside 'isGapped'\'s domain is not the same as being physically
--   gapless: @KitaevParams 3 1 0@ (@Delta_p = 0@, @|mu| = 3 > 2|t| = 2@) is a
--   physically gapped, ordinary (non-topological) band insulator --
--   @bulkGap@ is exactly @2.0@ there -- even though @Delta_p = 0@ places it
--   outside Prop. kitaev's winding-number domain. 'phaseLabel' must report
--   this as gapped-but-outside-domain, not as "gapless".
gappedOutsideDomainCheck :: Check
gappedOutsideDomainCheck = Check
  { checkName = "phaseLabel(mu=3,t=1,Delta=0) = gapped-but-outside-domain, not gapless"
  , checkOk   =    abs (bulkGap p - 2.0) < 1e-9
                && not (isGapped p)
                && phaseLabel p == "trivial-normal (outside invariant domain)"
  }
  where p = KitaevParams 3.0 1.0 0.0

-- | Regression pin for a rounding hazard in 'bulkGap': at @Delta_p = 0@,
--   @|d(k)|^2@ is the perfect square @(2t cos k + mu)^2@, exactly zero at its
--   root in exact arithmetic, but evaluating the expanded quadratic through
--   irrational @mu@, @t@ can round to a tiny *negative* candidate at that
--   root (@mu = sqrt 3@, @t = sqrt 2@ gives @g(x*) ~= -4.4e-16@) -- an
--   unclamped 'sqrt' of that is @NaN@, and @NaN < gapTolerance@ is @False@,
--   so 'phaseLabel' would silently fall through to "outside the invariant
--   domain" instead of "gapless" for a point that is, in fact, exactly on
--   the gapless normal-metal locus (@|mu| = 1.732... < 2|t| = 2.828...@).
--   Pins that 'bulkGap' is clamped to a small non-negative value (not @NaN@)
--   and 'phaseLabel' correctly reports "gapless".
bulkGapNoNaNCheck :: Check
bulkGapNoNaNCheck = Check
  { checkName = "bulkGap(mu=sqrt 3,t=sqrt 2,Delta=0) ~= 0, not NaN; phaseLabel = gapless"
  , checkOk   =    not (isNaN g)
                && g >= 0 && g < 1e-6
                && phaseLabel p == "gapless"
  }
  where
    p = KitaevParams (sqrt 3) (sqrt 2) 0
    g = bulkGap p

-- Prop (Cluster-state string order) ----------------------------------------

-- | The telescoping identity @K_{a+1} K_{a+3} ... K_{b-1} = S_{a,b}@ holds
--   exactly (same 'Pauli' record: same X/Z pattern and the same overall
--   phase) for *every* valid window of the given chain length, confirming
--   each @S_{a,b}@ is literally a stabilizer-group element, not merely equal
--   to one up to sign (bordism-realizability.tex:512-526).
telescopingExhaustiveCheck :: Int -> Check
telescopingExhaustiveCheck n = Check
  { checkName = "K_(a+1)...K_(b-1) = S(a,b) exactly, every valid window, n=" ++ show n
  , checkOk   = all telescopes (allWindows n)
  }
  where
    gens = clusterGenerators n
    telescopes w = productPauli n [ gens !! j | j <- [swA w + 1, swA w + 3 .. swB w - 1] ]
                     == stringOp w

-- | @Z_j@ anticommutes with its own generator @K_j@ (through the shared
--   central @X_j@); @X_j@ anticommutes with both flanking generators
--   @K_{j-1}@, @K_{j+1}@ (through their @Z_j@ factors) and commutes with its
--   own @K_j@ -- checked for *every* interior site, not one example. This is
--   the load-bearing bookkeeping behind @<Z_j> = <X_j> = 0@
--   (bordism-realizability.tex:526-529).
anticommutationExhaustiveCheck :: Int -> Check
anticommutationExhaustiveCheck n = Check
  { checkName = "Z_j~K_j; X_j~K_(j-1),K_(j+1); X_j comm K_j -- every interior j, n=" ++ show n
  , checkOk   = all checkAt [1 .. n - 2]
  }
  where
    gens = clusterGenerators n
    checkAt j =    anticommutes (single n LZ j) (gens !! j)
                && anticommutes (single n LX j) (gens !! (j - 1))
                && anticommutes (single n LX j) (gens !! (j + 1))
                && not (anticommutes (single n LX j) (gens !! j))

-- | Single-site expectations vanish at *every* site (not one example) -- the
--   outcome forced by 'anticommutationExhaustiveCheck' above.
noLocalOrderExhaustiveCheck :: Int -> Check
noLocalOrderExhaustiveCheck n = Check
  { checkName = "<Z_j> = <X_j> = 0, every site j=0.." ++ show (n - 1)
  , checkOk   = all (\j -> expectation gens (single n LZ j) == 0
                        && expectation gens (single n LX j) == 0)
                    [0 .. n - 1]
  }
  where gens = clusterGenerators n

-- | The string order is exactly @+1@ for *every* valid window of the given
--   chain length.
stringOrderOneExhaustiveCheck :: Int -> Check
stringOrderOneExhaustiveCheck n = Check
  { checkName = "<S(a,b)> = +1, every valid window, n=" ++ show n
  , checkOk   = all (\w -> stringOrder w == 1) (allWindows n)
  }

-- | The rotated string order equals @cos(theta)^m@ to five decimal places
--   over a 21-point grid spanning @[0, pi/2]@ (not two isolated angles) --
--   the precision to which the panel verified the decay
--   (bordism-realizability.tex:529-537).
degradationGridCheck :: String -> StringWindow -> Check
degradationGridCheck lbl w = Check
  { checkName = "<S(theta)> = cos^m(theta) to 5dp, 21-point grid on [0,pi/2] " ++ lbl
  , checkOk   = all matches thetas
  }
  where
    thetas = [ fromIntegral i * (pi / 2) / 20 | i <- [0 .. 20 :: Int] ]
    matches theta = roundTo5 (stringOrderRotated w theta) == roundTo5 (cos theta ^ numX w)
    roundTo5 :: Double -> Double
    roundTo5 x = fromIntegral (round (x * 1e5) :: Integer) / 1e5

-- All checks ----------------------------------------------------------------

-- | All deterministic checks, citing Prop (Kitaev-chain Z2 invariant,
--   bordism-realizability.tex:634-663) and Prop (Cluster-state string order,
--   bordism-realizability.tex:493-537).
allChecks :: [Check]
allChecks =
  [ dzEndpointsCheck "t=1, mu=1.9"      (KitaevParams 1.9 1.0 1.0)
  , dzEndpointsCheck "t=1.3, mu=-0.7"   (KitaevParams (-0.7) 1.3 0.6)
  , majoranaClosedFormCheck "t=1, mu=1.9 (topological)" (KitaevParams 1.9 1.0 1.0)
  , majoranaClosedFormCheck "t=1, mu=2.1 (trivial)"     (KitaevParams 2.1 1.0 1.0)
  , majoranaClosedFormCheck "t=0.8, mu=-3.0 (trivial)"  (KitaevParams (-3.0) 0.8 0.5)
  , majoranaFlipCheck
  , windingMajoranaAgreeCheck "t=1, mu=1.9 (topological)" (KitaevParams 1.9 1.0 1.0)
  , windingMajoranaAgreeCheck "t=1, mu=2.1 (trivial)"     (KitaevParams 2.1 1.0 1.0)
  , topologicalAgreesWithMajoranaCheck "t=1, mu=1.9" (KitaevParams 1.9 1.0 1.0) True
  , topologicalAgreesWithMajoranaCheck "t=1, mu=2.1" (KitaevParams 2.1 1.0 1.0) False
  , mkGappedRejectsCheck
  , gappedOutsideDomainCheck
  , bulkGapNoNaNCheck
  , telescopingExhaustiveCheck 8
  , telescopingExhaustiveCheck 10
  , anticommutationExhaustiveCheck 8
  , anticommutationExhaustiveCheck 10
  , noLocalOrderExhaustiveCheck 8
  , noLocalOrderExhaustiveCheck 10
  , stringOrderOneExhaustiveCheck 8
  , stringOrderOneExhaustiveCheck 10
  , degradationGridCheck "n=8, S(0,6)" (mkWindowOrError 8 0 6)
  , degradationGridCheck "n=10, S(2,8)" (mkWindowOrError 10 2 8)
  ]

-- | Run every deterministic check; print a per-check pass/fail line; return
--   overall success.
runAllProofs :: IO Bool
runAllProofs = do
  putStrLn "=== Deterministic Examples & Finite Exhaustive Checks (Prop kitaev, Prop cluster) ==="
  mapM_ report allChecks
  let passed = length (filter checkOk allChecks)
      total  = length allChecks
  putStrLn (show passed ++ "/" ++ show total ++ " checks passed")
  pure (all checkOk allChecks)
  where
    report :: Check -> IO ()
    report c =
      putStrLn ("  " ++ (if checkOk c then "OK  " else "FAIL") ++ "  " ++ checkName c)
