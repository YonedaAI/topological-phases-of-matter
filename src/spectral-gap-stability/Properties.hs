{-|
Module      : Properties
Description : QuickCheck properties for the transverse-field Ising diagonalization.
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Executable checks tracking the assertions of Part III (\"The Uniformly Gapped
Substack\"). Each property cites the paper claim it exercises. The exact trace
identities double as a validation of the self-contained Jacobi eigensolver: a wrong
spectrum would violate @sum lambda_j = 0@ or @sum lambda_j^2 = ((N-1)+N g^2)2^N@.

'gapAt' and 'perturbedGap' return @Maybe Double@ (see "TFIM"): every 'Config' built
below is valid by construction (via 'config'), so these always yield @Just@ in
practice, but the properties still handle @Nothing@ exhaustively -- turning a
would-be-impossible case into a reported test failure rather than a type error.
-}
module Properties
  ( runAllProperties
  ) where

import Test.QuickCheck
import TFIM

-- | A small random configuration (dimension kept modest so the full-spectrum
-- diagonalization stays fast under repeated QuickCheck sampling). The coupling is
-- drawn mostly from the continuum but, three times in ten, pinned exactly to one of
-- the boundary values @g in {0,1,2}@ (the ferromagnetic endpoint, the discriminant
-- @Sigma@, and the paramagnetic endpoint) -- points a purely continuous generator
-- would almost never land on exactly.
newtype SmallConfig = SmallConfig Config deriving Show

instance Arbitrary SmallConfig where
  arbitrary = do
    n <- choose (2, 5)
    g <- frequency [ (1, pure 0), (1, pure 1), (1, pure 2), (7, choose (0, 2)) ]
    pure (SmallConfig (config n g))

-- | A configuration together with a small longitudinal-field perturbation.
data LipCase = LipCase Config [Double] deriving Show

instance Arbitrary LipCase where
  arbitrary = do
    n  <- choose (2, 5)
    g  <- choose (0, 2)
    vs <- vectorOf n (choose (-0.3, 0.3))
    pure (LipCase (config n g) vs)

-- | A field value strictly inside the paramagnetic phase.
newtype Paramag = Paramag Double deriving Show

instance Arbitrary Paramag where
  arbitrary = Paramag <$> choose (1.3, 2.0)

-- | An ordered pair of paramagnetic field values @g1 < g2@.
data MonoCase = MonoCase Double Double deriving Show

instance Arbitrary MonoCase where
  arbitrary = do
    a     <- choose (1.4, 1.8)
    delta <- choose (0.05, 0.2)
    pure (MonoCase a (a + delta))

-- | A positive field value (bounded away from @0@ and @infinity@ for the duality
-- check).
newtype PosField = PosField Double deriving Show

instance Arbitrary PosField where
  arbitrary = PosField <$> choose (0.1, 5.0)

-- | Trace identity @Tr H = sum_j lambda_j = 0@ (eq. (17) of the paper). Also an
-- independent check that the eigensolver conserves the trace.
prop_traceZero :: SmallConfig -> Property
prop_traceZero (SmallConfig cfg) =
  counterexample ("sum of eigenvalues = " ++ show s) (abs s <= 1.0e-6)
  where s = sum (spectrum cfg)

-- | Trace identity @Tr H^2 = sum_j lambda_j^2 = ((N-1) + N g^2) 2^N@ (eq. (17)).
-- Validates the Jacobi eigensolver against an exact closed form.
prop_traceSq :: SmallConfig -> Property
prop_traceSq (SmallConfig cfg) =
  counterexample ("got " ++ show s2 ++ ", expected " ++ show ex)
    (abs (s2 - ex) <= 1.0e-5 * ex)
  where
    s2 = sum (map (\x -> x * x) (spectrum cfg))
    ex = expectedTraceSq cfg

-- | The Hamiltonian matrix is symmetric (real spectrum).
prop_symmetric :: SmallConfig -> Bool
prop_symmetric (SmallConfig cfg) =
  and [ entryOf cfg r c == entryOf cfg c r
      | r <- [0 .. d - 1], c <- [0 .. d - 1] ]
  where d = dim (nSites cfg)

-- | Theorem III-A (finite-volume Lipschitz continuity): the 1-gap satisfies
-- @|gap(H+V) - gap(H)| <= 2||V||@ for any longitudinal perturbation @V@, with
-- @||V|| = sum_i |v_i|@.
prop_lipschitz :: LipCase -> Property
prop_lipschitz (LipCase cfg vs) =
  case (perturbedGap cfg vs, gapAt cfg) of
    (Just gp, Just g0) ->
      let dg  = abs (gp - g0)
          bnd = 2 * fieldOpNorm vs
      in counterexample ("|dgap| = " ++ show dg ++ ", bound 2||V|| = " ++ show bnd)
           (dg <= bnd + 1.0e-6)
    _ -> counterexample "gapAt/perturbedGap returned Nothing for a valid config" False

-- | Gap positivity away from criticality: in the paramagnetic phase (@g >= 1.3@),
-- at fixed @N = 6@, the 1-gap is strictly positive (Section 8.2).
prop_gapPositive :: Paramag -> Bool
prop_gapPositive (Paramag g) = maybe False (> 1.0e-6) (gapAt (config 6 g))

-- | Monotone growth of the gap with @g@ in the paramagnetic phase, at @N = 6@
-- (the finite-size reflection of the thermodynamic gap @approx 2(g-1)@).
prop_monotone :: MonoCase -> Property
prop_monotone (MonoCase g1 g2) =
  case (gapAt (config 6 g1), gapAt (config 6 g2)) of
    (Just gp1, Just gp2) ->
      counterexample
        ("g1=" ++ show g1 ++ " gap=" ++ show gp1 ++
         " ; g2=" ++ show g2 ++ " gap=" ++ show gp2)
        (gp1 <= gp2 + 1.0e-6)
    _ -> counterexample "gapAt returned Nothing for a valid N=6 config" False

-- | Kramers--Wannier duality of the exact thermodynamic gap:
-- @gap(g) = g * gap(1/g)@, a spectrum symmetry of the free-fermion solution.
prop_kwDuality :: PosField -> Property
prop_kwDuality (PosField g) =
  counterexample
    ("gap(g) = " ++ show (freeFermionGap g) ++
     " ; g*gap(1/g) = " ++ show (g * freeFermionGap (1 / g)))
    (abs (freeFermionGap g - g * freeFermionGap (1 / g)) < 1.0e-9)

-- | Run every property, reporting a pass/fail summary.
runAllProperties :: IO Bool
runAllProperties = do
  putStrLn "=== QuickCheck property verification ==="
  results <- sequence
    [ check "eq.(17): Tr H = 0"                         prop_traceZero
    , check "eq.(17): Tr H^2 identity (solver check)"   prop_traceSq
    , check "Hamiltonian is symmetric"                  prop_symmetric
    , check "Thm III-A: gap is 2-Lipschitz"             prop_lipschitz
    , check "gap positive off criticality (g>=1.3)"     prop_gapPositive
    , check "gap monotone in g (paramagnetic)"          prop_monotone
    , check "Kramers-Wannier duality of exact gap"      prop_kwDuality
    ]
  let passed  = length (filter id results)
      nChecks = length results
  putStrLn (show passed ++ "/" ++ show nChecks ++ " properties passed")
  pure (and results)
  where
    check :: Testable p => String -> p -> IO Bool
    check name prop = do
      putStrLn ("  " ++ name)
      r <- quickCheckResult prop
      case r of
        Success{} -> pure True
        _         -> pure False
