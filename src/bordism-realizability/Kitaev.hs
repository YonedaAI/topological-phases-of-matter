{-|
Module      : Kitaev
Description : Kitaev Majorana-chain Z2 invariant (Proposition "Kitaev-chain Z2 invariant")
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Bogoliubov--de Gennes description of the 1D Kitaev p-wave chain and its Z2
topological invariant, computed two independent ways directly from the Bloch
Hamiltonian: (i) the winding number of the BdG d-vector (d_y, d_z) about the
origin, and (ii) the Majorana number M = sgn(d_z(0)) * sgn(d_z(pi)). Both are
quantized on the gapped locus and jump on the discriminant |mu| = 2|t|. This
module realizes Proposition (Kitaev-chain Z2 invariant) of Part V
(bordism-realizability.tex:634-663) and drives the invariant sweep printed by
"Main".

Proposition (Kitaev-chain Z2 invariant) applies only for @Delta_p /= 0@ and
off the discriminant @|mu| = 2|t|@ (paper:634-636); 'windingNumber' and
'majoranaNumber' remain total functions of every 'KitaevParams' (needed by
'muSweep' and 'detectBoundary', which must sweep straight through the
transition to find it), but 'isGapped' names the proposition's actual domain
precisely, rejecting @Delta_p ~= 0@ outright (not merely the codimension-1
discriminant) because the winding number is not a robustly-defined invariant
there at all; 'GappedKitaevParams' / 'mkGapped' let a caller obtain the
guarantee that the domain hypothesis holds before invoking the safe wrappers
'windingNumberG' / 'majoranaNumberG'.

Being outside 'isGapped'\'s domain is a different question from being
physically gapless, and 'phaseLabel' keeps the two separate: @Delta_p = 0@
splits into a genuinely gapless sub-case (@|mu| < 2|t|@, a normal metal whose
dispersion crosses zero) and a genuinely *gapped* sub-case (@|mu| > 2|t|@, an
ordinary trivial band insulator, @bulkGap > 0@) that merely lies outside the
winding number's domain. 'phaseLabel' reports the bulk gap's physical truth
first and only falls back to "outside the invariant domain" for points that
are gapped but not covered by the proposition.
-}
module Kitaev
  ( KitaevParams(..)
  , dVector
  , bulkGap
  , windingNumber
  , majoranaNumber
  , isTopological
  , isGapped
  , GappedKitaevParams
  , unGapped
  , mkGapped
  , windingNumberG
  , majoranaNumberG
  , phaseLabel
  , SweepRow(..)
  , muSweep
  , detectBoundary
  , planeBoundary
  ) where

-- | Parameters of the Kitaev chain: chemical potential, hopping, p-wave pairing.
data KitaevParams = KitaevParams
  { kpMu    :: !Double
  , kpT     :: !Double
  , kpDelta :: !Double
  } deriving (Eq, Show)

-- | BdG d-vector @(d_y, d_z)@ at lattice momentum @k@ in the Nambu basis:
--   @d_y(k) = 2 Delta sin k@, @d_z(k) = -2 t cos k - mu@.
dVector :: KitaevParams -> Double -> (Double, Double)
dVector (KitaevParams mu t del) k =
  (2 * del * sin k, negate (2 * t * cos k) - mu)

-- | Momentum grid @k@ in @[0, 2pi)@ with @n@ points.
momentumGrid :: Int -> [Double]
momentumGrid n = [ 2 * pi * fromIntegral i / fromIntegral n | i <- [0 .. n - 1] ]

-- | Bulk single-particle gap @2 * min_k |d(k)|@, computed as the exact minimum
--   (not a grid estimate) of the quadratic @|d(k)|^2 = a x^2 + b x + c@ in
--   @x = cos k in [-1,1]@, where @a = 4(t^2 - Delta_p^2)@, @b = 4 t mu@,
--   @c = 4 Delta_p^2 + mu^2@ (expanding @|d|^2 = 4 Delta_p^2 sin^2 k + (2t cos
--   k + mu)^2@ and substituting @sin^2 k = 1 - x^2@). The minimum of this
--   quadratic on @[-1,1]@ is at the interior critical point @x* = -b/(2a)@
--   when @a > 0@ (upward-opening parabola) and @x*@ lies in range; otherwise
--   the parabola is monotone or downward-opening on @[-1,1]@ and the minimum
--   is at an endpoint @x = +-1@ (i.e. @k = 0@ or @k = pi@). The candidate
--   minimum is clamped to @>= 0@ before the square root: @|d(k)|^2@ is
--   mathematically a sum of squares (hence exactly @>= 0@ for every real
--   @k@), but at @Delta_p = 0@ it is the perfect square @(2t cos k + mu)^2@,
--   and evaluating that square through the expanded @a x^2 + b x + c@ from
--   irrational @mu@, @t@ can round to a tiny *negative* number at the root
--   (e.g. @mu = sqrt 3@, @t = sqrt 2@, @Delta_p = 0@ gives @g(x*) ~= -4.4e-16@
--   from rounding in @a@, @b@, @c@ alone); an unclamped 'sqrt' of that would be
--   @NaN@, which then silently fails every comparison (including
--   @< gapTolerance@ in 'phaseLabel') rather than being recognized as the
--   gapless point it actually is.
bulkGap :: KitaevParams -> Double
bulkGap (KitaevParams mu t del) = 2 * sqrt (max 0 (minimum candidates))
  where
    a = 4 * (t * t - del * del)
    b = 4 * t * mu
    c = 4 * del * del + mu * mu
    g x = a * x * x + b * x + c
    endpoints = [g (-1), g 1]
    xStar = negate b / (2 * a)
    candidates
      | a > 0 && xStar >= -1 && xStar <= 1 = g xStar : endpoints
      | otherwise                          = endpoints

-- | Signed angular increment between two nonzero planar vectors, wrapped to @(-pi, pi]@.
angleStep :: (Double, Double) -> (Double, Double) -> Double
angleStep (y1, z1) (y2, z2) = wrap (atan2 z2 y2 - atan2 z1 y1)
  where
    wrap d
      | d > pi          = d - 2 * pi
      | d <= negate pi  = d + 2 * pi
      | otherwise       = d

-- | Winding number of @k |-> (d_y, d_z)@ about the origin as @k@ runs @0 -> 2pi@.
--   Returns @0@ (trivial) or @1@ (topological) on the gapped locus (@isGapped@).
--   Total over every 'KitaevParams' (needed by 'muSweep' and 'detectBoundary',
--   which sweep straight through the non-gapped locus to find it); prefer
--   'windingNumberG' when the caller needs the domain guarantee of Prop.
--   kitaev.
windingNumber :: KitaevParams -> Int
windingNumber p = abs (round (total / (2 * pi)))
  where
    ks    = momentumGrid 2000 ++ [2 * pi]
    pts   = map (dVector p) ks
    total = sum (zipWith angleStep pts (drop 1 pts))

-- | Sign of a real number as an 'Int' in @{-1, 0, 1}@.
intSign :: Double -> Int
intSign x
  | x > 0     = 1
  | x < 0     = -1
  | otherwise = 0

-- | @d_z@ at the two particle-hole-invariant momenta, in closed form:
--   @d_z(0) = -2t - mu@, @d_z(pi) = 2t - mu@ (bordism-realizability.tex:660).
--   Computed directly by subtraction, with no trigonometric evaluation, so
--   'majoranaNumber' below does not depend on @cos@/@sin@ rounding to
--   bit-exact @1@/@-1@/@0@ at @k = 0, pi@ (contrast 'dVector', which is
--   evaluated generically at every momentum and does use @cos@/@sin@).
dzEndpoints :: KitaevParams -> (Double, Double)
dzEndpoints (KitaevParams mu t _) = (negate (2 * t) - mu, 2 * t - mu)

-- | Majorana number @M = sgn(d_z(0)) * sgn(d_z(pi))@ in @{-1, 0, +1}@:
--   @-1@ topological, @+1@ trivial, @0@ gapless (on the discriminant).
--   Computed from the closed-form endpoints ('dzEndpoints'), not by
--   evaluating 'dVector' at @k = 0, pi@: this makes the exact zero
--   @d_z(pi) = 2t - mu = 0@ at the discriminant @mu = 2t@ a plain subtraction,
--   true on any platform, rather than contingent on libm's @cos pi@. Total
--   over every 'KitaevParams', for the same reason as 'windingNumber'; prefer
--   'majoranaNumberG' for the domain-safe version.
majoranaNumber :: KitaevParams -> Int
majoranaNumber p = let (dz0, dzPi) = dzEndpoints p in intSign dz0 * intSign dzPi

-- | Topological iff @Delta /= 0@ and @|mu| < 2|t|@.
isTopological :: KitaevParams -> Bool
isTopological (KitaevParams mu t del) = del /= 0 && abs mu < 2 * abs t

-- | Numerical tolerance for "exactly zero" / "exactly on the discriminant".
gapTolerance :: Double
gapTolerance = 1e-9

-- | Is the point numerically on the discriminant @|mu| = 2|t|@?
onDiscriminant :: KitaevParams -> Bool
onDiscriminant (KitaevParams mu t _) = abs (abs mu - 2 * abs t) < gapTolerance

-- | Is this parameter point in the domain where Prop. kitaev
--   (bordism-realizability.tex:634-636) actually applies: @Delta_p /= 0@
--   (numerically) and off the discriminant @|mu| = 2|t|@? This is strictly
--   more than "off the discriminant": at @Delta_p = 0@ the BdG d-vector
--   degenerates onto the @d_z@-axis (@d_y = 2 Delta_p sin k = 0@ identically),
--   so the winding number is not a robustly-defined invariant even where
--   @|mu| /= 2|t|@ -- e.g. @Delta_p = 0@, @|mu| < 2|t|@ is a gapless normal
--   metal (the BdG dispersion @-2t cos k - mu@ crosses zero), not a
--   topological phase.
isGapped :: KitaevParams -> Bool
isGapped p@(KitaevParams _ _ del) = abs del > gapTolerance && not (onDiscriminant p)

-- | A 'KitaevParams' point known to satisfy Prop. kitaev's hypothesis
--   (@Delta_p /= 0@, off the discriminant @|mu| = 2|t|@). Constructible only
--   via 'mkGapped' (the constructor is not exported), so 'windingNumberG' and
--   'majoranaNumberG' are guaranteed to be evaluated only where the
--   proposition -- and hence its quantization and jump claims -- applies.
newtype GappedKitaevParams = GappedKitaevParams KitaevParams
  deriving (Eq, Show)

-- | Recover the underlying parameters of a validated point.
unGapped :: GappedKitaevParams -> KitaevParams
unGapped (GappedKitaevParams p) = p

-- | Smart constructor: @Just@ the wrapped point iff 'isGapped'; @Nothing@
--   otherwise (@Delta_p ~= 0@, including the gapless @Delta_p = 0, |mu| <
--   2|t|@ locus, or exactly on the discriminant @|mu| = 2|t|@).
mkGapped :: KitaevParams -> Maybe GappedKitaevParams
mkGapped p
  | isGapped p = Just (GappedKitaevParams p)
  | otherwise  = Nothing

-- | Winding number, restricted to the domain of Prop. kitaev.
windingNumberG :: GappedKitaevParams -> Int
windingNumberG = windingNumber . unGapped

-- | Majorana number, restricted to the domain of Prop. kitaev.
majoranaNumberG :: GappedKitaevParams -> Int
majoranaNumberG = majoranaNumber . unGapped

-- | Human-readable phase label, reporting the physical truth of whether the
--   bulk gap ('bulkGap') closes -- not merely whether Prop. kitaev's winding
--   number happens to be defined there. These are different questions:
--   'isGapped' is the narrower domain hypothesis of the invariant
--   (@Delta_p /= 0@, off the discriminant), used by 'mkGapped' to guard
--   'windingNumberG' / 'majoranaNumberG'; but a point can fail that
--   hypothesis while still being physically gapped. In particular
--   @Delta_p = 0@, @|mu| > 2|t|@ is an ordinary (non-topological) band
--   insulator with @bulkGap > 0@ -- e.g. @KitaevParams 3 1 0@ has
--   @bulkGap = 2.0@ -- not a gapless system, even though the winding number
--   is not a meaningful invariant there (the d-vector curve degenerates onto
--   the @d_z@-axis). Conversely @Delta_p = 0@, @|mu| < 2|t|@ genuinely is
--   gapless (a normal metal: the dispersion @-2t cos k - mu@ crosses zero,
--   so @bulkGap = 0@ exactly, since @|d(k)|^2@ is then the perfect square
--   @(2t cos k + mu)^2@). So: "gapless" iff @bulkGap@ closes; "topological"
--   / "trivial" iff additionally in Prop. kitaev's domain; otherwise
--   (gapped, but @Delta_p ~= 0@) an explicit third label, not a silent
--   misclassification as either "gapless" or "trivial".
phaseLabel :: KitaevParams -> String
phaseLabel p
  | bulkGap p < gapTolerance = "gapless"
  | isGapped p               = if isTopological p then "topological" else "trivial"
  | otherwise                = "trivial-normal (outside invariant domain)"

-- | One row of an invariant sweep.
data SweepRow = SweepRow
  { srMu       :: !Double
  , srWinding  :: !Int
  , srMajorana :: !Int
  , srGap      :: !Double
  , srLabel    :: !String
  } deriving (Eq, Show)

-- | Sweep @mu@ across the supplied values at fixed @t@, @Delta@; produce invariant rows.
muSweep :: Double -> Double -> [Double] -> [SweepRow]
muSweep t del mus =
  [ let p = KitaevParams mu t del
    in SweepRow mu (windingNumber p) (majoranaNumber p) (bulkGap p) (phaseLabel p)
  | mu <- mus ]

-- | Detect the phase boundary in @mu@ at fixed @t@, @Delta@ by locating the
--   first @mu >= 0@ where the winding number changes; returns the midpoint of
--   that step. The transition is found from the invariant, not hard-coded.
--   The scan range is bracketed dynamically around the analytic boundary
--   @2|t|@ (with headroom), rather than a fixed @[0,4]@ window, so detection
--   remains correct for any @t@, not only @|t| <= 2@. Returns 'Nothing' if
--   @Delta_p ~= 0@ (outside Prop. kitaev's domain -- see 'isGapped' -- so
--   there is no well-defined topological transition to detect) or if no sign
--   change is found on the scanned range.
detectBoundary :: Double -> Double -> Maybe Double
detectBoundary t del
  | abs del <= gapTolerance = Nothing
  | otherwise               = go rows
  where
    hi    = 2 * abs t + max 1 (abs t)  -- comfortably past the analytic boundary 2|t|
    steps = 800 :: Int
    step  = hi / fromIntegral steps
    mus   = [ fromIntegral i * step | i <- [0 .. steps] ]
    rows  = [ (mu, windingNumber (KitaevParams mu t del)) | mu <- mus ]
    go ((m1, w1) : rest@((m2, w2) : _))
      | w1 /= w2  = Just ((m1 + m2) / 2)
      | otherwise = go rest
    go _ = Nothing

-- | Analytic phase boundary @|mu| = 2|t|@; used to check 'detectBoundary'.
planeBoundary :: Double -> Double
planeBoundary t = 2 * abs t
