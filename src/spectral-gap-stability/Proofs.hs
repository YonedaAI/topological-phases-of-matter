{-|
Module      : Proofs
Description : Deterministic theorem-instance checks for Part III (spectral gap stability).
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Where "Properties" exercises the paper's claims as QuickCheck properties over
randomly generated configurations, this module checks them as /deterministic theorem
instances/: a fixed, finite list of test cases per claim, with no generator and no
shrinking. To be precise about what that is and is not: every check here is a finite
numerical evaluation at concrete, named points -- an instance of a theorem or lemma,
not a formal proof of it in the sense of a proof assistant. Several of the checks are
independent of the Jacobi eigensolver in "TFIM" altogether, validating the model
construction itself rather than the diagonalization; others exercise the solver
directly and are honestly reported as doing so.

  * 'checkTraceZero' and 'checkTraceSquare' recompute the trace identities
    \eqref{eq:traces} of the paper directly from the matrix entries
    ('hamiltonianMatrix'\/'entryOf'), never calling 'symEigenvalues', so these checks
    validate the Hamiltonian construction independently of the solver;

  * 'checkFieldOpNorm' verifies the exact combinatorial fact behind 'fieldOpNorm''s
    Haddock comment: the operator norm of a diagonal field @sum_i v_i Z_i@ equals
    @sum_i |v_i|@, saturated at the all-signs-aligned basis state;

  * 'checkWeylFullSpectrum' is a solver-dependent instance of Weyl monotonicity
    (\Cref{lem:weyl} of the paper) over the /entire/ ordered spectrum -- every level,
    not only the two the gap uses -- against the exact operator norm
    'checkFieldOpNorm' establishes;

  * 'checkLipschitzChain' is a solver-dependent instance of the proof of Theorem
    III-A(i) (\Cref{thm:IIIA}) itself, replayed as three separate steps -- Weyl at
    level 0, Weyl at level 1, triangle inequality -- rather than only its composed
    conclusion, which "Properties" already samples randomly as @prop_lipschitz@;

  * 'checkGapLocusOpen' is the corollary Theorem III-A(ii) at a concrete point: a
    perturbation kept under a quarter of the gap cannot close it;

  * 'checkKWDyadic' and 'checkKWGeneric' verify the Kramers--Wannier identity
    @gap(g) = g * gap(1\/g)@ (\eqref{eq:disp}, Section 8.1), derived algebraically
    from @g*(1-1\/g) = g-1@, at dyadic points (exact binary arithmetic) and generic
    points (tight tolerance) -- and 'checkGapAnchors' pins the three boundary values
    @g in {0,1,2}@ exactly, independently of the duality relationship itself (a
    uniformly mis-scaled 'freeFermionGap' would still satisfy the duality identity,
    since an overall constant factor cancels on both sides; the anchors below do not
    have that blind spot);

  * 'checkDiagonalClosedForm' and 'checkTwoByTwoClosedForm' validate 'symEigenvalues'
    itself, independently of the physics model, against textbook closed forms (a
    diagonal matrix's eigenvalues are its diagonal; a generic symmetric @2x2@ matrix
    has eigenvalues by the quadratic formula);

  * 'checkGZeroTFIM' and 'checkNEqualsOne' validate the solver against TFIM-specific
    closed forms at the model's own degenerate corners: @g=0@ (\eqref{eq:tfim} is
    already diagonal) and @N=1@ (a bare @-g X@ term, spectrum @[-|g|,|g|]@) -- solver
    coverage at chain lengths and couplings "Properties"'s continuous @N in [2,5]@
    generator reaches only by chance, if at all;

  * 'checkSolverTraceZero' and 'checkSolverTraceSquare' re-run \eqref{eq:traces}
    /through/ 'spectrum' at @N in {6,7,8}@, the lengths the paper's own numerics use
    (\Cref{sec:numerics-ed}) but "Properties"'s @choose (2,5)@ generator never
    reaches, closing that solver-coverage gap;

  * 'checkSolverConverges' exercises 'symEigenvalues' directly (not through
    'spectrum') at the largest dimension used here, confirming the convergence
    report is real -- residual and sweep count both present, sweep count under the
    cap -- rather than merely present in the type.

Scope. Theorems III-B and III-C are deliberately out of reach here: III-B is a
size-independent perturbation-threshold statement for the infinite-volume,
frustration-free\/LTQO stratum, and III-C is a uniform-clustering statement over a
profinite family, neither of which is a finite-@N@ diagonalization fact. Attempting
to "check" them numerically would repeat exactly the mistake Section 8.4 of the
paper warns against: no finite computation decides a thermodynamic-limit or
profinite-base property. This module stays within what Section 8 actually computes --
finite-volume, Theorem III-A territory -- and instantiates it more thoroughly than by
random sampling alone.
-}
module Proofs
  ( runAllInstances
  ) where

import Data.List (sort)
import Data.Maybe (fromMaybe)
import Text.Printf (printf)

import TFIM

-- * Small helpers

-- | The diagonal of a flat row-major @m x m@ matrix.
diagonalOf :: Int -> [Double] -> [Double]
diagonalOf m xs = [ xs !! (i * m + i) | i <- [0 .. m - 1] ]

-- | Sum of squares of every entry of a flat matrix. For a /symmetric/ matrix this is
-- @Tr(H^2)@, since @Tr(H^2) = sum_rc H_rc H_cr = sum_rc H_rc^2@.
sumOfSquares :: [Double] -> Double
sumOfSquares = sum . map (\x -> x * x)

-- | Equality up to an absolute tolerance.
approxEq :: Double -> Double -> Double -> Bool
approxEq tol a b = abs (a - b) <= tol

-- | Elementwise equality up to an absolute tolerance, for two lists already known to
-- have the same length.
approxEqList :: Double -> [Double] -> [Double] -> Bool
approxEqList tol xs ys = and (zipWith (approxEq tol) xs ys)

-- * eq. (17)/\eqref{eq:traces}: trace identities, checked independently of the eigensolver

-- | Configurations spanning the chain lengths used in the paper's numerics
-- (@N in {4,6,8}@ from "Main", widened here to @2..8@) and a representative spread of
-- couplings, including the discriminant @g=1@ and both phase endpoints.
traceCases :: [Config]
traceCases = [ config n g | n <- [2 .. 8], g <- [0.0, 0.7, 1.0, 1.5, 2.0] ]

-- | \eqref{eq:traces}, @Tr H(g) = 0@, recomputed from the matrix diagonal directly
-- (no 'symEigenvalues' call): each @Z_i Z_{i+1}@ pair contributes a diagonal +-1 that
-- cancels exactly when summed over the full @2^N@-dimensional hypercube basis.
checkTraceZero :: Config -> (String, Bool)
checkTraceZero cfg =
  ( printf "eq:traces instance: Tr H(N=%d,g=%.2f) = 0, from the matrix diagonal only" n g
  , approxEq 1.0e-9 total 0
  )
  where
    n     = nSites cfg
    g     = field cfg
    total = sum (diagonalOf (dim n) (hamiltonianMatrix cfg))

-- | \eqref{eq:traces}, @Tr H(g)^2 = ((N-1) + N g^2) 2^N@, recomputed as the sum of
-- squares of /every/ matrix entry (valid since @H@ is symmetric), independently of
-- the eigensolver, and checked against 'expectedTraceSq'.
checkTraceSquare :: Config -> (String, Bool)
checkTraceSquare cfg =
  ( printf "eq:traces instance: Tr H(N=%d,g=%.2f)^2 matches closed form, matrix entries only" n g
  , approxEq (1.0e-9 * max 1 expected) computed expected
  )
  where
    n        = nSites cfg
    g        = field cfg
    computed = sumOfSquares (hamiltonianMatrix cfg)
    expected = expectedTraceSq cfg

-- * Fixed perturbation instances shared by the Weyl / Lipschitz checks

-- | Deterministic (not sampled) configuration/field pairs, ranging over both phases
-- and several chain lengths.
fieldCases :: [(Config, [Double])]
fieldCases =
  [ (config 5 1.5, [0.3, -0.2, 0.1, 0.0, -0.4])
  , (config 4 0.8, [0.1,  0.1, 0.1, 0.1])
  , (config 6 1.2, [0.25, -0.25, 0.25, -0.25, 0.25, -0.25])
  , (config 3 1.0, [0.5, -1.0, 0.2])
  ]

-- | The exact combinatorial fact behind 'fieldOpNorm''s Haddock comment: the diagonal
-- perturbation @sum_i v_i Z_i@ achieves operator norm @sum_i |v_i|@ at the
-- all-signs-aligned basis state. Reconstructed through the public API only: the
-- perturbation matrix is @'hamiltonianWithField' - 'hamiltonianMatrix'@, exactly
-- diagonal because the two share the same off-diagonal branch, so its operator norm
-- is its largest absolute diagonal entry.
checkFieldOpNorm :: (Config, [Double]) -> (String, Bool)
checkFieldOpNorm (cfg, vs) =
  ( printf "opnorm(sum v_i Z_i) = sum|v_i|, N=%d g=%.2f (aligned basis state)" n g
  , approxEq 1.0e-9 achieved claimed
  )
  where
    n          = nSites cfg
    g          = field cfg
    d          = dim n
    diffMatrix = zipWith (-) (hamiltonianWithField cfg vs) (hamiltonianMatrix cfg)
    achieved   = maximum (map abs (diagonalOf d diffMatrix))
    claimed    = fieldOpNorm vs

-- | Solver-dependent instance of Lemma (Weyl monotonicity, \Cref{lem:weyl}):
-- @|lambda_k(H+V) - lambda_k(H)| <= ||V||@ for /every/ @k@, not only the two levels
-- the gap uses -- stronger, full-spectrum coverage than what "Properties" checks
-- only at the gap. Depends on 'spectrum'\/'spectrumWithField' (hence on the
-- eigensolver), unlike 'checkTraceZero'\/'checkTraceSquare'.
checkWeylFullSpectrum :: (Config, [Double]) -> (String, Bool)
checkWeylFullSpectrum (cfg, vs) =
  ( printf "lem:weyl instance: |lambda_k(H+V)-lambda_k(H)| <= ||V|| for all k, N=%d g=%.2f" n g
  , all (<= opnorm + 1.0e-6) diffs
  )
  where
    n      = nSites cfg
    g      = field cfg
    opnorm = fieldOpNorm vs
    diffs  = zipWith (\a b -> abs (a - b)) (spectrum cfg) (spectrumWithField cfg vs)

-- | Solver-dependent instance of the proof of Theorem III-A(i) (\Cref{thm:IIIA})
-- itself, replayed as three separate steps rather than only its composed
-- conclusion: Weyl at level 0, Weyl at level 1, then the triangle inequality
-- combining them into the @2||V||@ bound on the gap (with the norm-domination
-- constant @C_Lambda = 1@, exact for this perturbation class by 'checkFieldOpNorm').
checkLipschitzChain :: (Config, [Double]) -> (String, Bool)
checkLipschitzChain (cfg, vs) =
  ( printf "thm:IIIA instance: Weyl@0, Weyl@1, triangle => 2||V|| bound, N=%d g=%.2f" n g
  , weylAt0 && weylAt1 && triangle && composedBound
  )
  where
    n             = nSites cfg
    g             = field cfg
    tol           = 1.0e-6
    opnorm        = fieldOpNorm vs
    es            = spectrum cfg
    fs            = spectrumWithField cfg vs
    e0            = es !! 0
    e1            = es !! 1
    f0            = fs !! 0
    f1            = fs !! 1
    d0            = abs (f0 - e0)
    d1            = abs (f1 - e1)
    dgap          = abs ((f1 - f0) - (e1 - e0))
    weylAt0       = d0 <= opnorm + tol
    weylAt1       = d1 <= opnorm + tol
    triangle      = dgap <= d0 + d1 + tol
    composedBound = dgap <= 2 * opnorm + tol

-- | Theorem III-A(ii) (the finite-volume gapped locus is open), immediate from (i):
-- if @2||V|| < gap(Phi)@ then @Phi+V@ remains gapped. Checked at a
-- deep-paramagnetic point with perturbations deliberately kept under a quarter of
-- the gap. 'gapAt'\/'perturbedGap' return @Maybe Double@; @config 6 1.5@ is valid by
-- construction so both are @Just@ in practice, but the @Maybe@ is still threaded
-- honestly via its 'Monad' instance rather than assumed away.
checkGapLocusOpen :: (String, Bool)
checkGapLocusOpen =
  ( "thm:IIIA(ii) instance: 2||V|| < gap(Phi) => Phi+V stays gapped (open locus)"
  , fromMaybe False result
  )
  where
    cfg = config 6 1.5
    result = do
      g0 <- gapAt cfg
      let perSite = g0 / 24 -- fieldOpNorm(V) = 6*perSite = g0/4, so 2*fieldOpNorm(V) = g0/2 < g0
          smallFields =
            [ replicate 6 perSite
            , [ if even i then perSite else negate perSite | i <- [0 .. 5 :: Int] ]
            ]
          stillGapped vs = case perturbedGap cfg vs of
            Just gp -> 2 * fieldOpNorm vs < g0 && gp > 1.0e-6
            Nothing -> False
      pure (all stillGapped smallFields)

-- * Kramers--Wannier self-duality (\eqref{eq:disp}, Section 8.1)

-- | Dyadic test points (powers of two and their reciprocals), exactly representable
-- in binary floating point, so the identity below is checked to near machine
-- epsilon.
kwDyadicCases :: [Double]
kwDyadicCases = [0.25, 0.5, 1, 2, 4, 8]

-- | Generic (non-dyadic) test points, checked to a tight but non-zero tolerance.
kwGenericCases :: [Double]
kwGenericCases = [1.5, 0.6, 3.0, 0.1, 7.0]

-- | @gap(g) = g * gap(1\/g)@ (\eqref{eq:disp}, Section 8.1), derived algebraically
-- from @g*(1 - 1\/g) = g - 1@: taking absolute values (valid since @g>0@ multiplies
-- through the sign unchanged) gives @g*|1-1\/g| = |g-1| = |1-g|@, i.e.
-- @2|1-g| = g*2|1-1\/g|@. Checked here at dyadic points where the arithmetic is
-- exact.
checkKWDyadic :: Double -> (String, Bool)
checkKWDyadic g =
  ( printf "eq:disp instance: gap(%.4f) = %.4f * gap(1/%.4f)  [dyadic]" g g g
  , approxEq 1.0e-12 (freeFermionGap g) (g * freeFermionGap (1 / g))
  )

-- | The same identity at generic (non-dyadic) points.
checkKWGeneric :: Double -> (String, Bool)
checkKWGeneric g =
  ( printf "eq:disp instance: gap(%.4f) = %.4f * gap(1/%.4f)  [generic]" g g g
  , approxEq 1.0e-9 (freeFermionGap g) (g * freeFermionGap (1 / g))
  )

-- | Boundary anchors for \eqref{eq:disp}, pinned exactly rather than derived from
-- the duality relationship: a uniformly mis-scaled @freeFermionGap@ (multiplied
-- through by some wrong constant @c@) would still satisfy
-- @gap(g) = g*gap(1\/g)@ identically, since @c@ cancels on both sides, so duality
-- alone cannot rule that out. These three exact values close that gap.
checkGapAnchors :: [(String, Bool)]
checkGapAnchors =
  [ ( "eq:disp anchor: freeFermionGap 1 = 0 (the discriminant Sigma={g=1})"
    , freeFermionGap 1 == 0
    )
  , ( "eq:disp anchor: freeFermionGap 0 = 2 (ferromagnetic endpoint)"
    , freeFermionGap 0 == 2
    )
  , ( "eq:disp anchor: freeFermionGap 2 = 2 (paramagnetic endpoint)"
    , freeFermionGap 2 == 2
    )
  ]

-- * Closed-form validation of 'symEigenvalues' itself, independent of the physics model

-- | A diagonal matrix's eigenvalues are its diagonal entries. Exercises
-- 'symEigenvalues' directly (not through any 'Config') against a hand-built @4x4@
-- matrix unrelated to the TFIM Hamiltonian.
checkDiagonalClosedForm :: (String, Bool)
checkDiagonalClosedForm =
  ( "symEigenvalues: diagonal 4x4 matrix has its diagonal as eigenvalues"
  , case symEigenvalues 4 flatMatrix of
      Left _       -> False
      Right report -> approxEqList 1.0e-9 (eigenvalues report) expected
  )
  where
    d          = [3, -1, 2, 0] :: [Double]
    flatMatrix = [ if r == c then d !! r else 0 | r <- [0 .. 3], c <- [0 .. 3] ]
    expected   = sort d

-- | A generic symmetric @2x2@ matrix @[[a,b],[b,dd]]@ has eigenvalues
-- @(a+dd)\/2 +- sqrt(((a-dd)\/2)^2 + b^2)@ by the quadratic formula. Exercises
-- 'symEigenvalues' directly against this textbook closed form.
checkTwoByTwoClosedForm :: (String, Bool)
checkTwoByTwoClosedForm =
  ( "symEigenvalues: generic 2x2 symmetric matrix matches the quadratic closed form"
  , case symEigenvalues 2 [a, b, b, dd] of
      Left _       -> False
      Right report -> approxEqList 1.0e-9 (eigenvalues report) expected
  )
  where
    a, b, dd :: Double
    a        = 2
    b        = 1
    dd       = 4
    mid      = (a + dd) / 2
    rad      = sqrt (((a - dd) / 2) ^ (2 :: Int) + b * b)
    expected = sort [mid - rad, mid + rad]

-- * Closed-form validation at the model's own degenerate corners

-- | Chain lengths for the @g=0@ closed-form check: at @g=0@, \eqref{eq:tfim} has no
-- transverse-field term, so @H(0)@ is exactly the diagonal Ising energy already (see
-- 'checkGZeroTFIM').
gZeroCases :: [Int]
gZeroCases = [3, 4, 5, 6]

-- | At @g=0@ the Hamiltonian \eqref{eq:tfim} is exactly diagonal (every off-diagonal
-- branch of 'entryOf' evaluates to @negate 0 = 0@ or @0@ directly), so the closed
-- form for the spectrum is simply the sorted diagonal, obtainable from the public
-- API without touching the solver. Comparing that against 'spectrum' (which /does/
-- go through 'symEigenvalues') checks that the solver correctly reproduces an
-- already-diagonal input -- the degenerate case Properties.hs's continuous
-- generators essentially never land on exactly.
checkGZeroTFIM :: Int -> (String, Bool)
checkGZeroTFIM n =
  ( printf "solver closed form: TFIM g=0, N=%d, H already diagonal" n
  , approxEqList 1.0e-9 (spectrum cfg) expected
  )
  where
    cfg      = config n 0
    d        = dim n
    expected = sort (diagonalOf d (hamiltonianMatrix cfg))

-- | Field values for the @N=1@ closed-form check.
nEqualsOneCases :: [Double]
nEqualsOneCases = [0.0, 0.5, 1.0, 1.7, 2.0]

-- | At @N=1@, \eqref{eq:tfim} has no Ising bonds (the diagonal Ising energy is a sum
-- over an empty range), leaving the bare single-site Hamiltonian
-- @H(g) = -g X@, the @2x2@ matrix @[[0,-g],[-g,0]]@ with closed-form spectrum
-- @[-|g|, |g|]@ (trace @0@, determinant @-g^2@). @N=1@ is the smallest input
-- 'mkConfig' accepts, and Properties.hs's generator (@choose (2,5)@) never reaches
-- it.
checkNEqualsOne :: Double -> (String, Bool)
checkNEqualsOne g =
  ( printf "solver closed form: TFIM N=1, g=%.2f, spectrum = sort[-|g|,|g|]" g
  , approxEqList 1.0e-9 (spectrum cfg) expected
  )
  where
    cfg      = config 1 g
    expected = sort [negate (abs g), abs g]

-- * eq:traces through the solver, at chain lengths "Properties" never samples

-- | Configurations at @N in {6,7,8}@ -- the lengths the paper's own numerics use
-- (\Cref{sec:numerics-ed}, "Main"'s gap table) -- which "Properties"'s
-- @choose (2,5)@ generator for 'SmallConfig' cannot reach, so its trace-identity
-- properties never exercise the solver there.
solverTraceCases :: [Config]
solverTraceCases = [ config n g | n <- [6, 7, 8], g <- [0.0, 1.0, 2.0] ]

-- | \eqref{eq:traces}, @Tr H(g) = sum lambda_j = 0@, this time /through/ 'spectrum'
-- (the solver), at chain lengths "Properties" does not reach.
checkSolverTraceZero :: Config -> (String, Bool)
checkSolverTraceZero cfg =
  ( printf "eq:traces solver instance: Tr H(N=%d,g=%.2f) = sum of computed eigenvalues = 0" n g
  , approxEq 1.0e-6 (sum (spectrum cfg)) 0
  )
  where
    n = nSites cfg
    g = field cfg

-- | \eqref{eq:traces}, @Tr H(g)^2 = sum lambda_j^2@, this time /through/ 'spectrum',
-- at chain lengths "Properties" does not reach; tolerance matches
-- @Properties.prop_traceSq@'s own solver-based convention.
checkSolverTraceSquare :: Config -> (String, Bool)
checkSolverTraceSquare cfg =
  ( printf "eq:traces solver instance: Tr H(N=%d,g=%.2f)^2 matches closed form (solver)" n g
  , approxEq (1.0e-5 * max 1 expected) computed expected
  )
  where
    n        = nSites cfg
    g        = field cfg
    computed = sumOfSquares (spectrum cfg)
    expected = expectedTraceSq cfg

-- * Exercising the convergence-reporting solver API directly

-- | Direct exercise of 'symEigenvalues'\/'EigenReport' (not through 'spectrum'):
-- confirms the solver reports genuine convergence -- a sweep count strictly under
-- the cap and a non-negative residual -- for a representative @N=8@ matrix, the
-- largest dimension the paper's numerics use.
checkSolverConverges :: (String, Bool)
checkSolverConverges =
  ( "symEigenvalues: reports real convergence (sweeps < cap) at N=8"
  , case symEigenvalues (dim 8) (hamiltonianMatrix (config 8 1.5)) of
      Left _       -> False
      Right report -> sweepsUsed report < 100 && residual report >= 0
  )

-- | Run every deterministic theorem-instance check, reporting a pass/fail summary in
-- the style of 'Properties.runAllProperties'.
runAllInstances :: IO Bool
runAllInstances = do
  putStrLn "=== Theorem-instance verification (deterministic, no QuickCheck) ==="
  results <- mapM report checks
  let passed  = length (filter id results)
      nChecks = length results
  putStrLn ("  " ++ show passed ++ "/" ++ show nChecks ++ " theorem instances checked")
  pure (and results)
  where
    checks =
      map checkTraceZero traceCases ++
      map checkTraceSquare traceCases ++
      map checkFieldOpNorm fieldCases ++
      map checkWeylFullSpectrum fieldCases ++
      map checkLipschitzChain fieldCases ++
      [ checkGapLocusOpen ] ++
      map checkKWDyadic kwDyadicCases ++
      map checkKWGeneric kwGenericCases ++
      checkGapAnchors ++
      [ checkDiagonalClosedForm, checkTwoByTwoClosedForm ] ++
      map checkGZeroTFIM gZeroCases ++
      map checkNEqualsOne nEqualsOneCases ++
      map checkSolverTraceZero solverTraceCases ++
      map checkSolverTraceSquare solverTraceCases ++
      [ checkSolverConverges ]
    report (name, ok) = do
      putStrLn ("  [" ++ (if ok then "OK  " else "FAIL") ++ "] " ++ name)
      pure ok
