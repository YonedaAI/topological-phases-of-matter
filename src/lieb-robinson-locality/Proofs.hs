{-|
Module      : Proofs
Description : Equational-reasoning proofs of Paper I's locality lemmas, executable.
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Where "Properties" fuzzes the paper's claims with QuickCheck, this module *derives* a
selection of them: each proof below is written as a literate equational-reasoning chain (one
step per definition or inequality used in the paper's own proof), followed by an executable
check of that same chain at concrete witnesses. This is a lighter, dependency-free companion
to the Lean formalization of the same material, checking that the paper's algebra and the
Haskell implementation agree step by step rather than only at the final inequality.

Citations are to \label keys in @papers/latex/lieb-robinson-locality.tex@ together with the
section-local number, counted directly from the shared @[theorem]@ counter (Theorem,
Proposition, Lemma, Corollary, Definition, Example, Remark all share one counter per section,
reset at each @\section@): Definition 2.1 (lattice), Definition 2.2 (F-function), Lemma 2.3
(reweight), Lemma 2.4 (Z^d F-functions), Definition 2.5 (interaction / F-norm), Proposition
2.6 (BF is a Banach space), Theorem 3.1 (Lieb-Robinson bound), Proposition 3.2 (light cone /
velocity), Theorem 3.3 = Theorem I-A (Banach space + strongly continuous dynamics), Lemma 3.4
(Lipschitz continuity in the interaction), Proposition 3.5 (generator), Example 3.6 (TFIM).

These numbers were counted directly from every \section marker and theorem-environment
@\begin{...}@ in the current @.tex@ source (verified exhaustively, not sampled). An earlier
revision of this module found "FFunction", "Properties", "Main", and "Ising" citing three of
these results by different numbers (reweight as "Lemma 2.4" rather than 2.3, the F-norm as
"Definition 2.7" rather than 2.5, the velocity as "Proposition 2.9" rather than 3.2, and the
TFIM example as "Example 3.9, Section 9" rather than Example 3.6, Section 8), evidently
predating an edit to the paper's section structure; those citations have since been corrected
in place to match the recount below, so all five modules now agree.
-}
module Proofs
  ( runAllProofs
  , analyticUpperBoundTFIM
  , tfimFnormAt
  ) where

import FFunction
  ( FFunction, powerLaw, reweight, evalF, normFTrunc, convFTrunc, analyticVelocity )
import LinAlg ( opNorm, mmul, identM, addM, isWellFormedMatrix, opNormConverged )
import Ising ( pauliX, pauliZ, siteOp )

-- ---------------------------------------------------------------------------------------
-- Lemma 2.3 [lem:reweight] (Exponential reweighting): F_a(r) = e^{-ar} F(r) is again an
-- F-function with ||F_a|| <= ||F|| and C_{F_a} <= C_F.
-- ---------------------------------------------------------------------------------------

-- | Lemma 2.3, axiom (F1), pointwise step:
--
-- >   F_a(r)
-- > =   { definition: reweight a f, i.e. F_a(r) = e^{-ar} * F(r) }
-- >   e^{-ar} * F(r)
-- > <=  { a,r >= 0 so a*r >= 0, and t |-> e^{-t} is <= 1 on [0, infinity) }
-- >   1 * F(r)
-- > =   { identity of multiplication }
-- >   F(r)
--
-- Checked at a grid of (a, r) witnesses against a power-law F-function.
proof_reweightPointwise :: Either String ()
proof_reweightPointwise = mapM_ checkAt witnesses
  where
    f = powerLaw 2 0.3
    witnesses = [ (a, r) | a <- [0, 0.1, 0.5, 1, 3, 10], r <- [0, 0.25, 1, 5, 50] ]
    checkAt (a, r) =
      let lhs      = evalF (reweight a f) r        -- F_a(r), via the implementation
          unfolded = exp (negate a * r) * evalF f r -- unfold the definition of reweight
          decayFac = exp (negate a * r)              -- the isolated factor e^{-ar}
          rhs      = evalF f r                        -- F(r)
      in if abs (lhs - unfolded) > 1e-9
           then Left ("reweight does not unfold to its definition at a=" ++ show a
                       ++ " r=" ++ show r)
         else if decayFac > 1 + 1e-12
           then Left ("e^{-ar} > 1 at a=" ++ show a ++ " r=" ++ show r)
         else if unfolded > rhs + 1e-9
           then Left ("F_a(r) > F(r) at a=" ++ show a ++ " r=" ++ show r)
         else Right ()

-- | Lemma 2.3, axiom (F1), aggregate step: the truncated summability constant
-- @normFTrunc R f = F(0) + 2 * sum_{n=1}^{R} F(n)@ inherits the pointwise bound term by term:
--
-- >   ||F_a||_trunc(R)
-- > =   { definition of normFTrunc }
-- >   F_a(0) + 2 * sum_{n=1}^{R} F_a(n)
-- > <=  { proof_reweightPointwise at each n, plus: (forall i, x_i <= y_i) => sum x <= sum y }
-- >   F(0) + 2 * sum_{n=1}^{R} F(n)
-- > =   { definition of normFTrunc }
-- >   ||F||_trunc(R)
--
-- The check verifies the per-term domination (the actual content of Lemma 2.3) and that it
-- composes into the aggregate bound, not just the final inequality in isolation.
proof_reweightNormBound :: Either String ()
proof_reweightNormBound = mapM_ checkAt aWitnesses
  where
    f  = powerLaw 1 0.5
    rr = 200 :: Int
    aWitnesses = [0, 0.1, 0.5, 1, 2, 5]
    checkAt a =
      let pointwiseOK = and
            [ evalF (reweight a f) (fromIntegral n) <= evalF f (fromIntegral n) + 1e-12
            | n <- [0 .. rr] ]
          lhsSum = normFTrunc rr (reweight a f)
          rhsSum = normFTrunc rr f
      in if not pointwiseOK
           then Left ("per-term domination fails for a=" ++ show a)
         else if lhsSum > rhsSum + 1e-9
           then Left ("aggregate ||F_a|| > ||F|| for a=" ++ show a)
         else Right ()

-- | Lemma 2.3, axiom (F2): the geometry actually used by 'convFTrunc' is the 1-D triple
-- @(dist(x,z), dist(z,y), dist(x,y)) = (|z|, |z-1|, 1)@. The paper's argument is:
--
-- >   F_a(|z|) * F_a(|z-1|) / F_a(1)
-- > =   { unfold reweight three times }
-- >   (e^{-a|z|} F(|z|)) * (e^{-a|z-1|} F(|z-1|)) / (e^{-a} F(1))
-- > =   { regroup: exponentials combine, the F-ratio factors out }
-- >   e^{-a(|z|+|z-1|-1)} * (F(|z|) F(|z-1|) / F(1))
-- > <=  { triangle inequality |z|+|z-1| >= |z-(z-1)| = 1, so the exponent is >= 0, and a >= 0 }
-- >   1 * (F(|z|) F(|z-1|) / F(1))
-- > =   { identity }
-- >   F(|z|) F(|z-1|) / F(1)
--
-- summed over z and combined with the sum-monotonicity of proof_reweightNormBound to give
-- @C_{F_a} <= C_F@. Checked term-by-term (the regrouping identity, the sign of the triangle
-- slack, and the resulting domination) and then in aggregate.
proof_reweightConvBound :: Either String ()
proof_reweightConvBound = mapM_ checkAt aWitnesses
  where
    f  = powerLaw 1 0.5
    rr = 200 :: Int
    aWitnesses = [0, 0.1, 0.5, 1, 2, 5]
    checkAt a = do
      mapM_ (checkTerm a) [negate rr .. rr]
      let lhs = convFTrunc rr (reweight a f)
          rhs = convFTrunc rr f
      if lhs > rhs + 1e-9
        then Left ("aggregate C_{F_a} > C_F for a=" ++ show a)
        else Right ()
    checkTerm a z =
      let dxz           = fromIntegral (abs z)       :: Double
          dzy           = fromIntegral (abs (z - 1)) :: Double
          dxy           = 1                           :: Double
          triangleSlack = dxz + dzy - dxy              -- >= 0 by the triangle inequality
          expFactor     = exp (negate a * triangleSlack)
          ratioF        = evalF f dxz * evalF f dzy / evalF f dxy
          ratioFa       = evalF (reweight a f) dxz * evalF (reweight a f) dzy
                            / evalF (reweight a f) dxy
          regrouped     = expFactor * ratioF
      in if triangleSlack < negate 1e-9
           then Left ("triangle inequality violated at z=" ++ show z)
         else if expFactor > 1 + 1e-12
           then Left ("exponential factor exceeds 1 at z=" ++ show z ++ " a=" ++ show a)
         else if abs (ratioFa - regrouped) > 1e-9
           then Left ("regrouping identity mismatch at z=" ++ show z ++ " a=" ++ show a)
         else if ratioFa > ratioF + 1e-9
           then Left ("per-term domination fails at z=" ++ show z ++ " a=" ++ show a)
         else Right ()

-- ---------------------------------------------------------------------------------------
-- Lemma 2.4 [lem:zd-Ffun] (Polynomial F-functions on Z^d): not exercised anywhere in
-- "Properties"; new coverage.
-- ---------------------------------------------------------------------------------------

-- | All points of @Z^d@ within l1-ball radius @r@ of the origin, by direct enumeration of the
-- bounding box rather than a shell-degeneracy formula: correct by construction (the number of
-- points at each l1-distance falls out of the enumeration itself), and fast enough at the
-- truncation radii used below.
zdBall :: Int -> Int -> [[Int]]
zdBall d r = [ pt | pt <- sequence (replicate d [negate r .. r]), sum (map abs pt) <= r ]

-- | Genuine Z^d (l1) truncated summability constant: sum of @F(|y|_1)@ over lattice points
-- @y@ within l1-radius @R@ of the origin, with real per-shell degeneracy (unlike
-- 'normFTrunc', which is 1-D-only and assumes exactly two points per shell).
normZdTrunc :: Int -> Int -> FFunction -> Double
normZdTrunc d r f = sum [ evalF f (fromIntegral (sum (map abs pt))) | pt <- zdBall d r ]

-- | Genuine Z^d (l1) truncated convolution constant at base points @(origin, y)@: sums
-- @F(dist(origin,z)) F(dist(z,y))@ over actual lattice points @z@ within l1-radius @R@ of the
-- origin, again with real degeneracy (unlike 'convFTrunc', which is 1-D-only).
convZdTruncAt :: Int -> Int -> [Int] -> FFunction -> Double
convZdTruncAt d r y f =
  let origin   = replicate d 0
      dist p q = sum (zipWith (\a b -> abs (a - b)) p q)
      total    = sum [ evalF f (fromIntegral (dist origin z)) * evalF f (fromIntegral (dist z y))
                      | z <- zdBall d r ]
  in total / evalF f (fromIntegral (dist origin y))

-- | Lemma 2.4: on @(Z^d, l^1)@, @F_eps(r) = (1+r)^{-(d+eps)}@ satisfies
-- @C_{F_eps} <= 2^{d+eps+1} ||F_eps||@, checked here by genuine @Z^d@ enumeration
-- ('zdBall'/'normZdTrunc'/'convZdTruncAt') for @d = 1, 2, 3@ and two separations @y@ per @d@
-- (Definition 2.2's @C_F@ is itself a supremum over all base-point pairs, not only nearest
-- neighbours), at truncation radius @R = 12@.
--
-- An earlier version of this check reused the 1-D-only 'normFTrunc'/'convFTrunc' even when
-- @d@ was 2 or 3 and only at separation 1 -- an overclaim of @Z^d@ coverage the review
-- correctly flagged, since those functions assume exactly two lattice points per shell (true
-- only on @Z@; in @d@ dimensions the count grows like @n^{d-1}@, per the paper's own proof).
-- This version enumerates the actual lattice, so the degeneracy is whatever the enumeration
-- finds, not an assumption.
proof_zdConvBound :: Either String ()
proof_zdConvBound = mapM_ checkAt witnesses
  where
    rr = 12 :: Int
    witnesses =
      [ (d, eps, y)
      | d   <- [1, 2, 3 :: Int]
      , eps <- [0.25, 0.5, 1.0, 2.0 :: Double]
      , y   <- [ 1 : replicate (d - 1) 0, 2 : replicate (d - 1) 0 ]
      ]
    checkAt (d, eps, y) =
      let f    = powerLaw d eps
          bnd  = 2 ** (fromIntegral d + eps + 1)
          nrm  = normZdTrunc d rr f
          conv = convZdTruncAt d rr y f
      in if conv > bnd * nrm + 1e-6
           then Left ("C_F > 2^(d+eps+1) ||F|| at d=" ++ show d ++ " eps=" ++ show eps
                       ++ " y=" ++ show y
                       ++ ": C_F=" ++ show conv ++ " bound=" ++ show (bnd * nrm))
           else Right ()

-- ---------------------------------------------------------------------------------------
-- Example 3.6 [ex:tfim] (Transverse-field Ising chain): ties the Ising/LinAlg modules to the
-- F-norm apparatus of FFunction; new coverage, and the first place any module checks the two
-- against each other.
-- ---------------------------------------------------------------------------------------

-- | The physical fact behind Example 3.6's arithmetic: a single-site Pauli operator and a
-- nearest-neighbour Pauli-Pauli bond both have operator norm 1 (Pauli matrices are unitary
-- and involutive, and a Kronecker product of unitaries is unitary), so a coefficient @J@ or
-- @h@ becomes a *term operator norm* @|J|@ or @|h|@ unchanged. Checked directly against
-- 'opNorm' on the embedded matrices, on a 2-site chain.
proof_operatorNormsUnit :: Either String ()
proof_operatorNormsUnit = do
  checkNorm "single-site X" (siteOp 2 0 pauliX)
  checkNorm "single-site Z" (siteOp 2 0 pauliZ)
  checkNorm "bond Z_0 Z_1"  (mmul (siteOp 2 0 pauliZ) (siteOp 2 1 pauliZ))
  where
    checkNorm name m =
      let nrm = opNorm m
      in if abs (nrm - 1) > 1e-6
           then Left (name ++ " operator norm is " ++ show nrm ++ ", expected 1")
           else Right ()

-- | Example 3.6's closed form for the TFIM F-norm, as a reusable function of the couplings
-- @(J, h)@ against a chosen F-function: @max{ (|h|+2|J|)/F(0), |J|/F(1) }@. Exported
-- indirectly via 'analyticUpperBoundTFIM' below, so Main's demo and this proof share one
-- source of truth for the formula instead of risking the two drifting apart.
tfimFnormAt :: Double -> Double -> FFunction -> Double
tfimFnormAt jj hh f = max ((abs hh + 2 * abs jj) / evalF f 0) (abs jj / evalF f 1)

-- | Example 3.6's closed form for the TFIM F-norm,
-- @||Phi_TFIM||_F = max{ (|h|+2|J|)/F(0), |J|/F(1) }@, from: a diagonal pair @x=y@ collects
-- the on-site field plus its (up to two) incident bonds, a nearest-neighbour pair collects
-- the one bond between them, and every other pair collects nothing (finite range). Checked by
-- directly summing @||Phi(X)||@ over the interaction's actual finite support list
-- (Definition 2.5's inner sum), on a chain long enough to contain an interior site, and
-- comparing to 'tfimFnormAt'.
proof_tfimFnorm :: Either String ()
proof_tfimFnorm = mapM_ checkAt witnesses
  where
    n = 9 :: Int
    witnesses = [ (1.0, 1.0), (1.0, 0.4), (0.3, 2.0), (2.0, 2.0), (1.0, negate 1.0) ]
    checkAt (jj, hh) =
      let f       = powerLaw 1 0.5
          singles = [ ([k],       abs hh) | k <- [0 .. n - 1] ]
          bonds   = [ ([k, k + 1], abs jj) | k <- [0 .. n - 2] ]
          terms   = singles ++ bonds
          weight x y = sum [ w | (supp, w) <- terms, x `elem` supp, y `elem` supp ]
          ratio x y  = weight x y / evalF f (fromIntegral (abs (x - y)))
          computed   = maximum [ ratio x y | x <- [0 .. n - 1], y <- [0 .. n - 1] ]
          closedForm = tfimFnormAt jj hh f
      in if abs (computed - closedForm) > 1e-9
           then Left ("TFIM F-norm mismatch at J=" ++ show jj ++ " h=" ++ show hh
                       ++ ": computed=" ++ show computed ++ " closed-form=" ++ show closedForm)
           else Right ()

-- | Proposition 3.2's velocity bound @v = 2 ||Phi||_{F_a} C_{F_a} / a@ for the TFIM
-- interaction, optimized numerically over the reweighting parameter @a@ on the family
-- @F_a(r) = e^{-ar} (1+r)^{-1.5}@ (Lemma 2.3's reweighting applied to Lemma 2.4's polynomial
-- weight with @eps = 0.5@) -- exactly the construction Example 3.6 describes: "its
-- optimization over the reweighting parameter a produces a finite group velocity, which we
-- exhibit numerically." Exported so Main's demo reports a genuine 'analyticVelocity'
-- computation tied to the actual TFIM F-norm, instead of a disconnected closed-form guess.
analyticUpperBoundTFIM :: Double -> Double -> Double
analyticUpperBoundTFIM jj hh = minimum [ vAt a | a <- [0.02, 0.04 .. 6.0] ]
  where
    baseF = powerLaw 1 0.5
    vAt a =
      let fa  = reweight a baseF
          bA  = tfimFnormAt jj hh fa
          cFa = convFTrunc 300 fa
      in analyticVelocity bA cFa a

-- ---------------------------------------------------------------------------------------
-- Proposition 3.2 [prop:velocity] (Light cone and velocity): "Properties" already checks
-- positivity and monotonicity in B_a; here we check the exact algebraic law behind it.
-- ---------------------------------------------------------------------------------------

-- | The velocity @v = 2 B_a C_{F_a} / a@ is linear (not just monotone) in @B_a@:
--
-- >   v(lambda * B_a, C_{F_a}, a)
-- > =   { definition of analyticVelocity }
-- >   2 * (lambda * B_a) * C_{F_a} / a
-- > =   { commutativity/associativity of multiplication }
-- >   lambda * (2 * B_a * C_{F_a} / a)
-- > =   { definition of analyticVelocity }
-- >   lambda * v(B_a, C_{F_a}, a)
proof_velocityHomogeneity :: Either String ()
proof_velocityHomogeneity = mapM_ checkAt witnesses
  where
    witnesses =
      [ (ba, cfa, a, lam)
      | ba  <- [0.5, 1, 3]
      , cfa <- [0.5, 2, 7]
      , a   <- [0.1, 1, 4]
      , lam <- [0.5, 1, 2, 10]
      ]
    checkAt (ba, cfa, a, lam) =
      let lhs = analyticVelocity (lam * ba) cfa a
          rhs = lam * analyticVelocity ba cfa a
      in if abs (lhs - rhs) > 1e-9 * max 1 (abs rhs)
           then Left ("velocity not homogeneous at Ba=" ++ show ba ++ " lambda=" ++ show lam)
           else Right ()

-- ---------------------------------------------------------------------------------------
-- Lemma 3.4 [lem:dynamics-lipschitz] (Continuity of the dynamics in the interaction): the
-- constant underlying Theorem I-A [thm:banach]'s continuity claim; not computed anywhere
-- else in the code, so this is new coverage.
-- ---------------------------------------------------------------------------------------

-- | The Lipschitz constant of Lemma 3.4, recorded in the paper's constants appendix as
-- @K = 2 ||A|| |supp A| ||F|| T e^{2 B C_F T}@ on the ball @||.||_F <= B@ over @|t| <= T@.
lipschitzConstant :: Double -> Double -> Double -> Double -> Double -> Double -> Double
lipschitzConstant normA suppSize normF tt bb cF =
  2 * normA * suppSize * normF * tt * exp (2 * bb * cF * tt)

-- | @K@ is positive and strictly increasing in the time horizon @T@ and in the norm-ball
-- radius @B@: both enter only through an increasing exponential, and @T@ also appears as a
-- positive linear prefactor. This is the quantitative content behind Lemma 3.4's Duhamel
-- estimate: a longer time horizon or a larger interaction ball can only cost more Lipschitz
-- constant, never less.
proof_lipschitzMonotone :: Either String ()
proof_lipschitzMonotone = mapM_ checkAt witnesses
  where
    witnesses =
      [ (normA, sz, normF, cF, bb, tt)
      | normA <- [1, 2], sz <- [1, 3], normF <- [1, 5]
      , cF <- [0.5, 2], bb <- [0.5, 3], tt <- [0.1, 1, 4]
      ]
    dT, dB :: Double
    dT = 0.37
    dB = 0.29
    checkAt (normA, sz, normF, cF, bb, tt) =
      let k0 = lipschitzConstant normA sz normF tt bb cF
          kT = lipschitzConstant normA sz normF (tt + dT) bb cF
          kB = lipschitzConstant normA sz normF tt (bb + dB) cF
      in if k0 <= 0
           then Left "Lipschitz constant K is not positive"
         else if kT <= k0
           then Left ("K is not increasing in T at T=" ++ show tt)
         else if kB <= k0
           then Left ("K is not increasing in B at B=" ++ show bb)
         else Right ()

-- ---------------------------------------------------------------------------------------
-- Proposition 2.6 [prop:banach-space] (BF is a Banach space): "Properties" already checks
-- subadditivity of the sup-of-ratios; here we add the other norm axiom (absolute
-- homogeneity), and re-derive subadditivity termwise rather than only checking the final
-- inequality.
-- ---------------------------------------------------------------------------------------

-- | Absolute homogeneity and the triangle inequality for the sup-of-ratios
-- @sup_i a_i / w_i@ that defines the F-norm in Definition 2.5:
--
-- >   sup_i |lambda a_i| / w_i
-- > =   { |lambda a_i| = |lambda| |a_i|, absolute value is multiplicative }
-- >   sup_i (|lambda| |a_i|) / w_i
-- > =   { |lambda| >= 0 is a common factor, pulls out of a sup over positive weights }
-- >   |lambda| * sup_i |a_i| / w_i
--
-- and, for the triangle inequality, @(a_i+b_i)/w_i <= a_i/w_i + b_i/w_i <= sup(a/w) +
-- sup(b/w)@ termwise, so the bound survives taking the sup over @i@ on the left.
-- (Completeness, the one nontrivial part of Proposition 2.6, is an analytic fact about
-- Cauchy sequences and is not a computational check.)
proof_fnormTriangle :: Either String ()
proof_fnormTriangle = mapM_ checkAt witnesses
  where
    sampleLists   = [[1, 2, 3], [0.5, 4, 0.25, 9], [7]] :: [[Double]]
    positiveLists = [[1, 1, 1], [2, 0.5, 4, 1], [3]]    :: [[Double]]
    lambdas       = [0, 0.5, 1, 3] :: [Double]
    witnesses =
      [ (as, bs, ws, lam)
      | as <- sampleLists, bs <- sampleLists, ws <- positiveLists, lam <- lambdas ]
    supRatio xs ws = maximum (zipWith (/) xs ws)
    checkAt (as, bs, ws, lam)
      | n < 1     = Right ()
      | otherwise =
          let a = take n as
              b = take n bs
              w = take n ws
              homoLHS = supRatio (map (\x -> abs (lam * x)) a) w
              homoRHS = abs lam * supRatio (map abs a) w
              triLHS  = supRatio (zipWith (+) a b) w
              triRHS  = supRatio a w + supRatio b w
          in if abs (homoLHS - homoRHS) > 1e-9
               then Left "absolute homogeneity fails"
             else if triLHS > triRHS + 1e-9
               then Left "triangle inequality fails"
             else Right ()
      where
        n = minimum [length as, length bs, length ws]

-- ---------------------------------------------------------------------------------------
-- Coverage matrix for Theorems I-A / I-B / I-C. A finite Haskell program only ever computes
-- on finite data; the theorems' content spans tiers that are and are not reachable that way,
-- and this table says which is which, rather than letting "N/N proofs checked" imply blanket
-- coverage of headline theorems that are partly analytic or condensed-set-theoretic.
--
-- >  Theorem I-A [thm:banach] (Banach space + strongly continuous infinite-volume dynamics)
-- >    (1) BF is a Banach space              COMPUTATIONAL   proof_fnormTriangle checks
-- >                                                           homogeneity and the termwise
-- >                                                           triangle inequality;
-- >                                                           completeness (Cauchy
-- >                                                           sequences) is not computational
-- >                                                           and is not checked here.
-- >    (2) finite-volume Lieb-Robinson bound  COMPUTATIONAL   proof_operatorNormsUnit +
-- >                                                           proof_tfimFnorm feed the exact
-- >                                                           bound Main checks pointwise
-- >                                                           against the TFIM simulation.
-- >    (3) infinite-volume limit tau^Phi_t    NOT COMPUTATIONAL: a limit over Lambda -> L of
-- >                                                           finite-volume automorphisms; no
-- >                                                           finite program computes an
-- >                                                           infinite-volume limit, only
-- >                                                           finite truncations of it.
-- >    (4) Lipschitz-in-Phi constant K        COMPUTATIONAL   proof_lipschitzMonotone checks
-- >                                                           the formula's sign and
-- >                                                           monotonicity, not the Duhamel
-- >                                                           derivation that produces it.
-- >
-- >  Theorem I-B [thm:condensed-dynamics] (condensed dynamics morphism)
-- >    entirely NOT COMPUTATIONAL: condensed sets are sheaves on the site of profinite sets,
-- >    and "the dynamics is a morphism of condensed sets" is a statement in that topos, with
-- >    no finite-data representative to compute on. Out of scope for this file by
-- >    construction, not by omission.
-- >
-- >  Theorem I-C [thm:uniform-lr] (profinite families and the uniform light cone)
-- >    (1) profinite-family / compatible-system structure   NOT COMPUTATIONAL, same reason as
-- >                                                          I-B.
-- >    (2) uniform velocity over the family parameter        COMPUTATIONAL   the velocity
-- >                                                          formula is the same for every
-- >                                                          s in the base, so uniformity
-- >                                                          reduces to B_a staying bounded as
-- >                                                          the parameter varies; this is
-- >                                                          I-C's one piece of finite-data
-- >                                                          content and is exactly what
-- >                                                          proof_uniformOverParameterBox
-- >                                                          checks below.
-- ---------------------------------------------------------------------------------------

-- | Theorem I-C [thm:uniform-lr], the one computational piece per the coverage matrix above:
-- the paper's own numerics section describes exhibiting that the velocity "stays finite and
-- bounded as (J,h) range over a compact box, illustrating the uniform-over-the-base content
-- of Theorem I-C: the velocity does not blow up as the parameters vary within bounds." This
-- checks exactly that on the TFIM's (J,h) family, using the same 'analyticUpperBoundTFIM'
-- Main's demo reports.
proof_uniformOverParameterBox :: Either String ()
proof_uniformOverParameterBox =
  case [ (jj, hh, v) | (jj, hh) <- box, let v = analyticUpperBoundTFIM jj hh, v < 0 || v > uniformBound ] of
    ((jj, hh, v) : _) ->
      Left ("velocity out of the uniform range at J=" ++ show jj ++ " h=" ++ show hh
            ++ ": v=" ++ show v)
    [] -> Right ()
  where
    box          = [ (jj, hh) | jj <- [0.2, 0.6 .. 3.0], hh <- [0.2, 0.6 .. 3.0] ]
    uniformBound = 200 :: Double -- generous, parameter-independent ceiling for this box

-- ---------------------------------------------------------------------------------------
-- Matrix well-formedness and opNorm convergence: computational responses to the "matrix
-- operations are not type safe" and "opNorm can underestimate" findings, scoped to the actual
-- matrices this program builds rather than a full dimension-indexed 'Matrix' rewrite (see
-- LinAlg's Haddock for why that larger rewrite was not done here).
-- ---------------------------------------------------------------------------------------

-- | The concrete matrices the TFIM demo actually builds and multiplies are well-formed
-- (rectangular and square, per 'isWellFormedMatrix') -- the precondition 'mmul' and 'addM'
-- rely on but do not check themselves is met in practice, on a small chain.
proof_matricesWellFormed :: Either String ()
proof_matricesWellFormed = mapM_ checkOne matrices
  where
    n = 4 :: Int
    matrices =
      [ ("identity",      identM n)
      , ("siteOp X",      siteOp n 0 pauliX)
      , ("siteOp Z",      siteOp n 2 pauliZ)
      , ("bond Z_0 Z_1",  mmul (siteOp n 0 pauliZ) (siteOp n 1 pauliZ))
      , ("sum X_0 + X_1", addM (siteOp n 0 pauliX) (siteOp n 1 pauliX))
      ]
    checkOne (name, m)
      | isWellFormedMatrix m = Right ()
      | otherwise = Left (name ++ " is not a well-formed (rectangular/square) matrix")

-- | 'opNorm's power iteration (used throughout the TFIM commutator-norm simulation) has
-- actually converged on the same building-block matrices, per 'opNormConverged's residual
-- check: the "certified upper bound, or residual check" alternative the review asked for.
proof_opNormCertified :: Either String ()
proof_opNormCertified = mapM_ checkOne matrices
  where
    n = 4 :: Int
    matrices =
      [ ("siteOp X",     siteOp n 0 pauliX)
      , ("bond Z_0 Z_1", mmul (siteOp n 0 pauliZ) (siteOp n 1 pauliZ))
      ]
    checkOne (name, m)
      | opNormConverged m = Right ()
      | otherwise = Left (name ++ ": opNorm power iteration did not converge to tolerance")

-- ---------------------------------------------------------------------------------------

-- | Run every equational-reasoning proof check, printing a compact pass/fail line for each.
runAllProofs :: IO Bool
runAllProofs = do
  putStrLn "=== Equational-reasoning proof checks ==="
  results <- sequence
    [ chk "Lemma 2.3    reweight pointwise bound (F1)"         proof_reweightPointwise
    , chk "Lemma 2.3    reweight summability bound (F1 agg.)"  proof_reweightNormBound
    , chk "Lemma 2.3    reweight convolution bound (F2)"       proof_reweightConvBound
    , chk "Lemma 2.4    Z^d convolution/summability bound"     proof_zdConvBound
    , chk "Example 3.6  Pauli/bond operator norms are 1"       proof_operatorNormsUnit
    , chk "Example 3.6  TFIM F-norm closed form"                proof_tfimFnorm
    , chk "Prop 3.2     velocity homogeneity in B_a"            proof_velocityHomogeneity
    , chk "Lemma 3.4    Lipschitz constant (Thm I-A) monotone"  proof_lipschitzMonotone
    , chk "Prop 2.6     F-ratio-norm homogeneity + triangle"    proof_fnormTriangle
    , chk "Thm I-C      uniform velocity over (J,h) box"        proof_uniformOverParameterBox
    , chk "LinAlg       demo matrices well-formed"              proof_matricesWellFormed
    , chk "LinAlg       opNorm power-iteration certified"       proof_opNormCertified
    ]
  let passed = length (filter id results)
      total  = length results
  putStrLn ("  " ++ show passed ++ "/" ++ show total ++ " proofs checked")
  return (and results)
  where
    chk :: String -> Either String () -> IO Bool
    chk name result = case result of
      Right () -> putStrLn ("  [OK]   " ++ name) >> return True
      Left msg -> putStrLn ("  [FAIL] " ++ name ++ ": " ++ msg) >> return False
