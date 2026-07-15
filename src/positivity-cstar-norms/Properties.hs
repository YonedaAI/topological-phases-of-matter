{-|
Module      : Properties
Description : QuickCheck properties for the finite-dimensional C*-algebra facts
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Randomized checks of the elementary facts underpinning Section~4 (positivity and
the state space), Section~5 (GNS), and Section~9 (the finite-level crossed
product) of the paper:

  * 'prop_cauchySchwarz' --- the Cauchy-Schwarz inequality for a state,
    @|phi(a* b)|^2 <= phi(a* a) phi(b* b)@ (the inequality that makes the GNS
    null space a left ideal, \Cref{prop:gns}, "GNS is a functor");
  * 'prop_conjPositive' --- positivity of @rho -> V rho V*@ (complete positivity
    of the elementary Kraus map; keeps states inside the positive cone,
    \Cref{prop:cone}, "Condensation preserves the positive cone and order unit");
  * 'prop_normSubmult' --- submultiplicativity of the operator norm,
    @||a b|| <= ||a|| ||b||@ (a Banach-algebra axiom, sharpened to the
    C*-identity used in \Cref{thm:statespace}, Theorem II-A);
  * 'prop_gnsReconstruct' --- the GNS reconstruction identity
    @<Omega, pi(a) Omega> = Tr(rho a)@, the defining identity of
    \Cref{prop:gns}, "GNS is a functor";
  * 'prop_blochPositivity' --- a qubit density matrix is positive iff its Bloch
    vector lies in the closed unit ball (\Cref{ex:bloch}, the @n=2@ instance of
    the condensed state space of \Cref{thm:statespace}, Theorem II-A);
  * 'prop_choleskyEigAgree' --- the eigenvalue and Cholesky tests agree on
    positive DEFINITENESS away from the singular boundary (a strictly
    interior notion; see 'Proofs.posCheck'). This is distinct from, and
    strictly stronger than, the closed positive SEMIDEFINITE cone @A_+@ of
    \Cref{thm:statespace}, Theorem II-A, which 'prop_starSquarePositive'
    below tests directly, and which 'Proofs.semidefCheck' checks including
    its boundary (@diag(1,0)@: positive but singular);
  * 'prop_xpAssoc' --- associativity of the finite crossed-product convolution
    underlying \Cref{thm:crossed}, Theorem II-C;
  * 'prop_xpAdjointAntimult' --- anti-multiplicativity of the crossed-product
    involution, @(a b)* = b* a*@, making it a @*@-algebra (Theorem II-C);
  * 'prop_xpInclusionHom' --- functoriality of the crossed product in finite
    quotients: the periodization map is a @*@-homomorphism
    (\Cref{thm:crossed}, Theorem II-C, the headline claim of the section);
  * 'prop_cstarIdentity' --- the C*-identity @||a* a|| = ||a||^2@
    (\Cref{thm:statespace}, Theorem II-A);
  * 'prop_mkDensityValid' --- @mkDensity@ always lands in the state space
    @St(M_3)@ (\Cref{thm:statespace}, Theorem II-A);
  * 'prop_stateNormalized' --- every state is normalized, @phi(1) = 1@
    (\Cref{thm:statespace}, Theorem II-A);
  * 'prop_statePositiveOnSquares' --- every state is positive on squares,
    @phi(a* a) >= 0@ (\Cref{thm:statespace}, Theorem II-A; \Cref{prop:gns});
  * 'prop_gnsGramPSD' --- the GNS Gram matrix is positive semidefinite
    (\Cref{prop:gns}, Section~5);
  * 'prop_starSquarePositive' --- the positive cone @A_+ = {a* a : a in A}@
    (\Cref{sec:cone}, underlying Theorem II-A) consists of positive
    semidefinite elements.
-}
module Properties
  ( runAllProperties
  ) where

import Data.Complex (Complex(..), magnitude)
import Test.QuickCheck

import Core
  ( Matrix, dim, adjoint, mmul, madd, stateEval
  , spectralNorm, isPositiveEig, isPositiveDefinite, minEigenvalue
  , mkDensity, isDensity, identity, fromRowsUnsafe, magSq
  , densityFromBloch )
import GNS (gnsData, gnsExpectation, GNSData(gnsGram))
import CrossedProduct
  ( XP, xpUnsafe, xpMul, xpAdjoint, xpApprox, includeXP )

-- ---------------------------------------------------------------------------
-- Generators
-- ---------------------------------------------------------------------------

-- | A single complex number with bounded real and imaginary parts.
genC :: Gen (Complex Double)
genC = (:+) <$> choose (-2, 2) <*> choose (-2, 2)

-- | A @d x d@ complex matrix.
genMatrix :: Int -> Gen Matrix
genMatrix d = fromRowsUnsafe <$> vectorOf d (vectorOf d genC)

-- | A general @3 x 3@ complex matrix.
newtype CMat = CMat Matrix
  deriving Show

instance Arbitrary CMat where
  arbitrary = CMat <$> genMatrix 3

-- | A @3 x 3@ density matrix (state).
newtype DensityMat = DensityMat Matrix
  deriving Show

instance Arbitrary DensityMat where
  arbitrary = DensityMat . mkDensity <$> genMatrix 3

-- | A @3 x 3@ Hermitian matrix.
newtype HermMat = HermMat Matrix
  deriving Show

instance Arbitrary HermMat where
  arbitrary = do
    m <- genMatrix 3
    pure (HermMat (madd m (adjoint m)))

-- | A Bloch vector with components in a range straddling the unit ball.
newtype BlochVec = BlochVec (Double, Double, Double)
  deriving Show

instance Arbitrary BlochVec where
  arbitrary = do
    x <- choose (-1.5, 1.5)
    y <- choose (-1.5, 1.5)
    z <- choose (-1.5, 1.5)
    pure (BlochVec (x, y, z))

-- | Level and ambient-group sizes for the finite crossed-product generators
-- below: the "top" algebra is @C(Z\/xpN) \\rtimes (Z\/xpBigN)@ and the "sub"
-- algebra (which includes into the top one) is @C(Z\/xpNPrime) \\rtimes (Z\/xpBigN)@,
-- with @xpNPrime | xpN | xpBigN@. Kept small so QuickCheck stays fast.
xpN, xpNPrime, xpBigN :: Int
xpN      = 4
xpNPrime = 2
xpBigN   = 4

-- | An element of the "top" finite crossed product @C(Z\/4) \\rtimes (Z\/4)@.
newtype XPTop = XPTop XP
  deriving Show

instance Arbitrary XPTop where
  arbitrary = XPTop . xpUnsafe <$> vectorOf xpBigN (vectorOf xpN genC)

-- | An element of the "sub" finite crossed product @C(Z\/2) \\rtimes (Z\/4)@,
-- the one 'includeXP' embeds into 'XPTop'.
newtype XPSub = XPSub XP
  deriving Show

instance Arbitrary XPSub where
  arbitrary = XPSub . xpUnsafe <$> vectorOf xpBigN (vectorOf xpNPrime genC)

-- ---------------------------------------------------------------------------
-- Properties
-- ---------------------------------------------------------------------------

-- | Cauchy-Schwarz for a state: @|phi(a* b)|^2 <= phi(a* a) phi(b* b)@.
prop_cauchySchwarz :: DensityMat -> CMat -> CMat -> Bool
prop_cauchySchwarz (DensityMat rho) (CMat a) (CMat b) =
  let phi x    = stateEval rho x
      lhs      = magSq (phi (adjoint a `mmul` b))
      rhsA     = realOf (phi (adjoint a `mmul` a))
      rhsB     = realOf (phi (adjoint b `mmul` b))
  in lhs <= rhsA * rhsB + 1e-6
  where
    realOf :: Complex Double -> Double
    realOf (re :+ _) = re

-- | Positivity of the map @rho -> V rho V*@ on a state @rho@.
prop_conjPositive :: DensityMat -> CMat -> Bool
prop_conjPositive (DensityMat rho) (CMat v) =
  isPositiveEig (v `mmul` rho `mmul` adjoint v)

-- | Submultiplicativity of the operator norm: @||a b|| <= ||a|| ||b||@.
prop_normSubmult :: CMat -> CMat -> Bool
prop_normSubmult (CMat a) (CMat b) =
  spectralNorm (a `mmul` b) <= spectralNorm a * spectralNorm b + 1e-6

-- | GNS reconstruction: @<Omega, pi(a) Omega> = Tr(rho a)@.
prop_gnsReconstruct :: DensityMat -> CMat -> Bool
prop_gnsReconstruct (DensityMat rho) (CMat a) =
  magnitude (gnsExpectation rho a - stateEval rho a) < 1e-6

-- | A qubit is positive iff its Bloch vector is in the closed unit ball.
prop_blochPositivity :: BlochVec -> Property
prop_blochPositivity (BlochVec r@(x, y, z)) =
  let nrm = sqrt (x * x + y * y + z * z)
  in abs (nrm - 1) > 1e-3 ==>            -- discard borderline vectors
       (isPositiveEig (densityFromBloch r) == (nrm <= 1))

-- | The eigenvalue and Cholesky positivity tests agree (away from the
-- singular boundary).
prop_choleskyEigAgree :: HermMat -> Property
prop_choleskyEigAgree (HermMat h) =
  let mn = minEigenvalue h
  in abs mn > 1e-3 ==>                    -- discard near-singular matrices
       (isPositiveDefinite h == (mn > 0))

-- | Associativity of the finite crossed-product convolution
-- (Theorem~II-C): @(a b) c = a (b c)@.
prop_xpAssoc :: XPTop -> XPTop -> XPTop -> Bool
prop_xpAssoc (XPTop a) (XPTop b) (XPTop c) =
  xpApprox 1e-6
    (xpMul xpN xpBigN (xpMul xpN xpBigN a b) c)
    (xpMul xpN xpBigN a (xpMul xpN xpBigN b c))

-- | Anti-multiplicativity of the crossed-product involution,
-- @(a b)* = b* a*@ (Theorem~II-C).
prop_xpAdjointAntimult :: XPTop -> XPTop -> Bool
prop_xpAdjointAntimult (XPTop a) (XPTop b) =
  xpApprox 1e-6
    (xpAdjoint xpN xpBigN (xpMul xpN xpBigN a b))
    (xpMul xpN xpBigN (xpAdjoint xpN xpBigN b) (xpAdjoint xpN xpBigN a))

-- | Functoriality of the finite crossed product in finite quotients
-- (\Cref{thm:crossed}, Theorem~II-C): the periodization map is a
-- @*@-homomorphism, @include(a b) = include(a) include(b)@.
prop_xpInclusionHom :: XPSub -> XPSub -> Bool
prop_xpInclusionHom (XPSub a) (XPSub b) =
  xpApprox 1e-6
    (includeXP xpNPrime xpN (xpMul xpNPrime xpBigN a b))
    (xpMul xpN xpBigN (includeXP xpNPrime xpN a) (includeXP xpNPrime xpN b))

-- | The C*-identity @||a* a|| = ||a||^2@, the defining axiom of a
-- C*-algebra that underlies the dual-ball norm of \Cref{thm:statespace},
-- Theorem~II-A. Previously exercised only once as a fixed demo
-- ("Main.demoNorm"); this is the randomized property version.
prop_cstarIdentity :: CMat -> Bool
prop_cstarIdentity (CMat a) =
  let na = spectralNorm a
  in abs (spectralNorm (adjoint a `mmul` a) - na * na) < 1e-6

-- | 'mkDensity' always lands in the state space @St(M_3)@ for an arbitrary
-- input matrix (\Cref{thm:statespace}, Theorem~II-A: the state space of a
-- matrix algebra is exactly its set of density matrices).
prop_mkDensityValid :: CMat -> Bool
prop_mkDensityValid (CMat m) = isDensity (mkDensity m)

-- | Every state is normalized, @phi(1) = 1@ --- part of the definition of a
-- state underlying \Cref{thm:statespace}, Theorem~II-A.
prop_stateNormalized :: DensityMat -> Bool
prop_stateNormalized (DensityMat rho) =
  magnitude (stateEval rho (identity (dim rho)) - 1) < 1e-6

-- | Every state is positive on squares, @phi(a* a) >= 0@ --- the defining
-- positivity axiom of a state (\Cref{thm:statespace}, Theorem~II-A) and the
-- inequality the GNS sesquilinear form (\Cref{prop:gns}) is built from.
prop_statePositiveOnSquares :: DensityMat -> CMat -> Bool
prop_statePositiveOnSquares (DensityMat rho) (CMat a) =
  realPart' (stateEval rho (adjoint a `mmul` a)) >= -1e-6
  where
    realPart' :: Complex Double -> Double
    realPart' (re :+ _) = re

-- | The GNS Gram matrix is positive semidefinite, as any Gram matrix of a
-- (possibly degenerate) inner product must be (\Cref{prop:gns}, Section~5;
-- see also 'GNS.gnsRank' for its exact rank).
prop_gnsGramPSD :: DensityMat -> Bool
prop_gnsGramPSD (DensityMat rho) = minEigenvalue (gnsGram (gnsData rho)) >= -1e-6

-- | The positive cone @A_+ = {a* a : a in A}@ underlying Theorem~II-A
-- (\Cref{sec:cone}) consists entirely of positive semidefinite elements:
-- @a* a@ is positive for every @a@, with no further hypotheses.
prop_starSquarePositive :: CMat -> Bool
prop_starSquarePositive (CMat a) = isPositiveEig (adjoint a `mmul` a)

-- ---------------------------------------------------------------------------
-- Runner
-- ---------------------------------------------------------------------------

-- | Run every property; return 'True' iff all pass.
runAllProperties :: IO Bool
runAllProperties = do
  putStrLn "=== QuickCheck Property Verification ==="
  results <- sequence
    [ check "Cauchy-Schwarz for states           " prop_cauchySchwarz
    , check "positivity of rho |-> V rho V*       " prop_conjPositive
    , check "operator-norm submultiplicativity    " prop_normSubmult
    , check "GNS reconstruction <Om,pi(a)Om>=Tr   " prop_gnsReconstruct
    , check "Bloch ball: positive <=> |r| <= 1    " prop_blochPositivity
    , check "eigenvalue vs Cholesky positivity    " prop_choleskyEigAgree
    , check "crossed-product associativity        " prop_xpAssoc
    , check "crossed-product involution antimult  " prop_xpAdjointAntimult
    , check "crossed-product inclusion is a hom.  " prop_xpInclusionHom
    , check "C*-identity ||a* a|| = ||a||^2       " prop_cstarIdentity
    , check "mkDensity always lands in St(M_3)    " prop_mkDensityValid
    , check "state normalization phi(1) = 1       " prop_stateNormalized
    , check "state positivity phi(a* a) >= 0      " prop_statePositiveOnSquares
    , check "GNS Gram matrix is PSD               " prop_gnsGramPSD
    , check "positive cone A_+ = {a* a} is PSD    " prop_starSquarePositive
    ]
  let nPassed = length (filter id results)
      nTotal  = length results
  putStrLn (show nPassed ++ "/" ++ show nTotal ++ " properties passed")
  pure (and results)
  where
    check :: Testable p => String -> p -> IO Bool
    check name prop = do
      putStr ("  " ++ name ++ " ... ")
      result <- quickCheckResult prop
      case result of
        Success{} -> putStrLn "OK" >> pure True
        _         -> putStrLn "FAILED" >> pure False
