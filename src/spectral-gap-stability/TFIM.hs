{-|
Module      : TFIM
Description : Transverse-field Ising chain: exact diagonalization and spectral gap.
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Exact diagonalization of the open-boundary transverse-field Ising chain

@
  H(g) = - sum_{i=1}^{N-1} Z_i Z_{i+1} - g sum_{i=1}^{N} X_i ,   g in [0,2],
@

accompanying Part III of /Topological Phases of Matter in the Condensed-Mathematics
Paradigm/ (\"The Uniformly Gapped Substack\"). The chain is a real symmetric
@2^N x 2^N@ matrix in the computational (Z-) basis: the @ZZ@ term is diagonal and the
transverse field @X_i@ flips a single spin. We diagonalize it with a self-contained
cyclic Jacobi routine (base only -- a mutable buffer via "Foreign.Marshal.Array", no
external linear-algebra dependency) and read off the spectral gap.

The point the module illustrates is the one made rigorously in the paper:

  * the thermodynamic single-particle gap is @2|1-g|@ (eq. (8) of the paper), so the
    gapless discriminant is the single point @Sigma = {g = 1}@;

  * away from @g = 1@ the gap is bounded below and the finite-volume gap is a
    Lipschitz function of the interaction (Theorem III-A) -- the numerical basis of
    stability;

  * no finite-@N@ computation decides the thermodynamic gap: for this model we know
    the answer only because it is exactly solvable, not because we diagonalized it.

Input validation. 'Config' is constructed only through 'mkConfig' (checked,
'Either'-returning) or 'config' (a convenience wrapper for statically-known-valid
literals, such as the test data in "Properties" and "Proofs", that crashes with a
descriptive message rather than silently accepting an invalid site count or a
non-finite field). The raw constructor is not exported. Likewise 'symEigenvalues' -
the one place a caller can hand this module an arbitrary matrix - checks the
dimension, length, finiteness, and symmetry of its input before touching the mutable
buffer, and reports whether the cyclic sweeps actually converged.
-}
module TFIM
  ( -- * Model
    Config
  , nSites
  , field
  , maxSites
  , mkConfig
  , config
  , dim
  , entryOf
  , hamiltonianMatrix
  , hamiltonianWithField
    -- * Spectrum and gaps
  , spectrum
  , spectrumWithField
  , gapAt
  , twoGapAt
  , perturbedGap
  , freeFermionGap
    -- * Exact identities (eigensolver validation)
  , expectedTraceSq
  , fieldOpNorm
    -- * Linear algebra
  , EigenReport(..)
  , symEigenvalues
  ) where

import Control.Monad (forM_)
import Data.Bits (popCount, testBit, xor)
import Data.List (sort, transpose)
import Foreign.Marshal.Array (allocaArray, pokeArray)
import Foreign.Ptr (Ptr)
import Foreign.Storable (peekElemOff, pokeElemOff)
import System.IO.Unsafe (unsafePerformIO)

-- | A chain configuration: number of spins and transverse-field strength @g@.
-- Construct one through 'mkConfig' or 'config'; the bare constructor is not
-- exported, so every 'Config' in scope anywhere outside this module is already
-- valid.
data Config = Config
  { nSites :: Int      -- ^ number of spins @N@ (open boundary conditions)
  , field  :: Double   -- ^ transverse field @g@
  } deriving (Eq, Show)

-- | Largest supported site count. Matches exactly the range the paper's own
-- numerics validate (\Cref{sec:numerics-ed}: \"we cap the dense computation at
-- @N=8@\") and this module's own solver-based checks exercise; a larger @N@ would
-- be constructible but neither paper-validated nor practically diagonalizable in
-- reasonable time (@N=12@ alone would already be a @4096 x 4096@ dense matrix).
maxSites :: Int
maxSites = 8

-- | Safely construct a 'Config'. Rejects a non-positive or oversized site count and
-- a non-finite field value, rather than letting an invalid one reach 'dim' (which
-- can overflow or be nonsensical) or the diagonalization.
mkConfig :: Int -> Double -> Either String Config
mkConfig n g
  | n < 1                   = Left ("mkConfig: nSites must be >= 1, got " ++ show n)
  | n > maxSites            = Left ("mkConfig: nSites must be <= " ++ show maxSites ++
                                     ", got " ++ show n)
  | isNaN g || isInfinite g = Left ("mkConfig: field must be finite, got " ++ show g)
  | otherwise               = Right (Config n g)

-- | Convenience wrapper around 'mkConfig' for statically-known-valid literals (test
-- data, demonstrations, where validity is an invariant of the literal itself, not
-- untrusted input to defend against). Crashes with a descriptive message if the
-- invariant is violated, which would indicate a bug in the calling code.
config :: Int -> Double -> Config
config n g = either (errorWithoutStackTrace . ("TFIM.config: " ++)) id (mkConfig n g)

-- | Hilbert-space dimension @2^N@.
dim :: Int -> Int
dim n = 2 ^ n

-- | Value of @Z_i@ (that is, @+1@ or @-1@) on computational basis state @b@.
-- Bit @i@ set means spin down, eigenvalue @-1@.
spinZ :: Int -> Int -> Double
spinZ i b = if testBit b i then -1 else 1

-- | Diagonal Ising energy @-sum_{i=0}^{N-2} z_i z_{i+1}@ on basis state @b@ (OBC).
diagEnergy :: Int -> Int -> Double
diagEnergy n b = negate (sum [ spinZ i b * spinZ (i + 1) b | i <- [0 .. n - 2] ])

-- | Matrix element @<r| H(g) |c>@ of the transverse-field Ising Hamiltonian.
-- Diagonal: the Ising energy. Off-diagonal @-g@ whenever @r@ and @c@ differ in
-- exactly one bit (a single spin flip by some @X_i@); zero otherwise.
entryOf :: Config -> Int -> Int -> Double
entryOf (Config n g) r c
  | r == c                  = diagEnergy n r
  | popCount (xor r c) == 1 = negate g
  | otherwise               = 0

-- | The dense Hamiltonian as a row-major flat list of length @(2^N)^2@.
hamiltonianMatrix :: Config -> [Double]
hamiltonianMatrix cfg = [ entryOf cfg r c | r <- [0 .. d - 1], c <- [0 .. d - 1] ]
  where d = dim (nSites cfg)

-- | Longitudinal-field energy @sum_i v_i z_i(b)@ of a field vector on basis state @b@.
fieldEnergy :: [Double] -> Int -> Double
fieldEnergy vs b = sum (zipWith (\i v -> v * spinZ i b) [0 ..] vs)

-- | The Hamiltonian @H(g) + sum_i v_i Z_i@ with an added longitudinal field, as a
-- flat matrix. Used in the perturbation experiment (Section 8.3 of the paper): a
-- diagonal perturbation of operator norm @sum_i |v_i|@. Requires
-- @length vs == nSites cfg@: a shorter or longer field vector would silently mean
-- something other than \"one field per site\" (an entry past the chain still
-- contributes, since 'spinZ' is @+1@ for any bit index beyond the actual sites, i.e.
-- a spurious constant shift), which would break the exact @sum_i |v_i|@
-- operator-norm identity 'fieldOpNorm' asserts.
hamiltonianWithField :: Config -> [Double] -> [Double]
hamiltonianWithField cfg vs
  | length vs /= nSites cfg =
      errorWithoutStackTrace
        ("TFIM.hamiltonianWithField: field vector has " ++ show (length vs) ++
         " entries, expected exactly nSites = " ++ show (nSites cfg))
  | otherwise = [ el r c | r <- [0 .. d - 1], c <- [0 .. d - 1] ]
  where
    d = dim (nSites cfg)
    el r c
      | r == c    = entryOf cfg r r + fieldEnergy vs r
      | otherwise = entryOf cfg r c

-- | Operator norm of the diagonal perturbation @sum_i v_i Z_i@, equal to
-- @sum_i |v_i|@ (the extreme aligned-sign basis state saturates it).
fieldOpNorm :: [Double] -> Double
fieldOpNorm = sum . map abs

-- | Full spectrum (ascending) of @H(g)@ by exact diagonalization. 'hamiltonianMatrix'
-- always produces a well-formed (correctly sized, finite, exactly symmetric) matrix
-- for any 'Config', so 'symEigenvalues' cannot fail here; if it ever did, that would
-- indicate a bug in this module's own construction rather than bad input, so we
-- crash loudly rather than silently propagate a possibly-wrong spectrum.
spectrum :: Config -> [Double]
spectrum cfg =
  either (errorWithoutStackTrace . ("TFIM.spectrum: " ++)) eigenvalues
    (symEigenvalues (dim (nSites cfg)) (hamiltonianMatrix cfg))

-- | Full spectrum (ascending) of the field-perturbed Hamiltonian. See 'spectrum'.
spectrumWithField :: Config -> [Double] -> [Double]
spectrumWithField cfg vs =
  either (errorWithoutStackTrace . ("TFIM.spectrumWithField: " ++)) eigenvalues
    (symEigenvalues (dim (nSites cfg)) (hamiltonianWithField cfg vs))

-- | Spectral gap @lambda_1 - lambda_0@ (the 1-gap), or 'Nothing' if the spectrum has
-- fewer than 2 levels. That is impossible for any 'Config' (@dim (nSites cfg) >= 2@
-- whenever @nSites cfg >= 1@, which 'mkConfig' enforces), but the result stays total
-- rather than silently falling back to @0@ -- itself a physically meaningful gap
-- value, at the critical point @g=1@, so it must never stand in for \"undefined\".
-- In the paramagnetic phase @g > 1@ this is the physical gap; in the ferromagnetic
-- phase @g < 1@ it is the exponentially small splitting of the near-degenerate
-- ground sector (see 'twoGapAt').
gapAt :: Config -> Maybe Double
gapAt = gapOf . spectrum

-- | The 2-gap @lambda_2 - lambda_0@: the physical gap above a two-fold ground
-- sector (the @m@-gap with @m = 2@ of Remark 4.4 in the paper), or 'Nothing' if the
-- spectrum has fewer than 3 levels (only possible at @nSites = 1@, a single-site
-- chain with no two-fold ground sector to speak of).
twoGapAt :: Config -> Maybe Double
twoGapAt cfg = case spectrum cfg of
  (e0 : _ : e2 : _) -> Just (e2 - e0)
  _                 -> Nothing

-- | 1-gap of the field-perturbed Hamiltonian, or 'Nothing' under the same condition
-- as 'gapAt'.
perturbedGap :: Config -> [Double] -> Maybe Double
perturbedGap cfg vs = gapOf (spectrumWithField cfg vs)

gapOf :: [Double] -> Maybe Double
gapOf (e0 : e1 : _) = Just (e1 - e0)
gapOf _             = Nothing

-- | Thermodynamic single-particle gap @min_k eps_k(g) = 2|1-g|@ from the exact
-- Jordan--Wigner solution (eq. (8) of the paper). This is the analytic reference the
-- finite-@N@ diagonalization approaches; it vanishes exactly on @Sigma = {g = 1}@.
freeFermionGap :: Double -> Double
freeFermionGap g = 2 * abs (1 - g)

-- | The exact value of @Tr H(g)^2 = sum_j lambda_j^2 = ((N-1) + N g^2) 2^N@
-- (eq. (17) of the paper). Comparing the diagonalized spectrum against this identity
-- validates the eigensolver.
expectedTraceSq :: Config -> Double
expectedTraceSq (Config n g) =
  (fromIntegral (n - 1) + fromIntegral n * g * g) * fromIntegral (dim n)

-- | Report accompanying a diagonalization: the ascending eigenvalues together with
-- convergence diagnostics -- the final off-diagonal Frobenius-norm residual and the
-- number of full sweeps performed -- so a caller can distinguish an accurate result
-- from one that merely exhausted the sweep cap.
data EigenReport = EigenReport
  { eigenvalues :: [Double]
  , residual    :: Double
  , sweepsUsed  :: Int
  } deriving (Eq, Show)

-- | The largest @m@ for which @m*m@ is guaranteed not to overflow 'Int' (with a
-- one-unit safety margin against 'Double'-@sqrt@ rounding at this magnitude), so
-- 'symEigenvalues' can reject an oversized @m@ /before/ trusting @m*m@ for anything
-- -- length checks, allocation size, or row\/column indexing.
maxSafeDim :: Int
maxSafeDim = floor (sqrt (fromIntegral (maxBound :: Int) :: Double)) - 1

-- | Eigenvalues (ascending) of a real symmetric @m x m@ matrix given as a row-major
-- flat list, by the cyclic Jacobi rotation method. Robust for the small dimensions
-- used here (@m <= 256@, i.e. @dim maxSites@); eigenvectors are not computed.
--
-- Checked: rejects @m <= 0@, an @m@ so large that @m*m@ could overflow 'Int', a
-- list whose length is not exactly @m*m@, any non-finite entry, and an asymmetric
-- input, with a descriptive 'Left' -- so a malformed matrix is refused rather than
-- risking an out-of-bounds write (too-long input, or an @m@ large enough that
-- @m*m@ wraps around to a smaller value the length check would then wrongly
-- accept) or a diagonalization of uninitialized memory (too-short input). On
-- success, convergence is judged by a tolerance /relative/ to the matrix's own
-- Frobenius norm (which cyclic Jacobi rotations, being orthogonal, preserve
-- exactly throughout the iteration), and failing to converge within the sweep cap
-- is itself a 'Left' rather than a silently returned, possibly inaccurate,
-- diagonal.
--
-- The computation runs in a freshly allocated mutable buffer and is referentially
-- transparent (same matrix, same result), so 'unsafePerformIO' is safe here.
symEigenvalues :: Int -> [Double] -> Either String EigenReport
symEigenvalues m xs
  | m <= 0                  = Left ("symEigenvalues: dimension must be positive, got " ++ show m)
  | m > maxSafeDim          = Left ("symEigenvalues: dimension " ++ show m ++
                                     " exceeds " ++ show maxSafeDim ++
                                     ", the largest m for which m*m cannot overflow Int")
  | length xs /= m * m      = Left ("symEigenvalues: expected " ++ show (m * m) ++
                                     " entries for a " ++ show m ++ "x" ++ show m ++
                                     " matrix, got " ++ show (length xs))
  | any nonFinite xs        = Left "symEigenvalues: matrix contains a NaN or infinite entry"
  | not (isSymmetric m xs)  = Left "symEigenvalues: matrix is not symmetric"
  | not converged           = Left ("symEigenvalues: Jacobi sweeps did not converge in " ++
                                     show sweeps ++ " sweeps (residual " ++ show resid ++
                                     ", tolerance " ++ show tol ++ ")")
  | otherwise               = Right (EigenReport (sort diagVals) resid sweeps)
  where
    nonFinite x = isNaN x || isInfinite x
    frob        = sqrt (sum (map (\x -> x * x) xs))
    tol         = 1.0e-13 * max 1 frob
    (diagVals, resid, sweeps, converged) =
      unsafePerformIO (allocaArray (m * m) (runJacobi m tol xs))
{-# NOINLINE symEigenvalues #-}

-- | Whether a flat row-major @m x m@ matrix is (exactly) symmetric. Every matrix
-- this module builds ('hamiltonianMatrix', 'hamiltonianWithField') is symmetric by
-- construction -- @entryOf cfg r c@ and @entryOf cfg c r@ take the same branch,
-- since both the @r==c@ guard and the Hamming-distance-1 guard are symmetric in
-- @(r,c)@ -- so this never rejects TFIM's own matrices; it exists to reject a
-- malformed one from any other caller of the exported 'symEigenvalues'. Implemented
-- via 'transpose' (row-chunk, transpose, compare), not per-entry @(!!)@ indexing
-- into the flat list, to stay @O(m^2)@ rather than @O(m^4)@.
isSymmetric :: Int -> [Double] -> Bool
isSymmetric m xs = xs == concat (transpose (chunksOf m xs))
  where
    chunksOf :: Int -> [a] -> [[a]]
    chunksOf _ [] = []
    chunksOf k ys = let (h, t) = splitAt k ys in h : chunksOf k t

-- | Poke the matrix into the buffer, diagonalize it, and read back the (unsorted)
-- diagonal together with the convergence diagnostics.
runJacobi :: Int -> Double -> [Double] -> Ptr Double -> IO ([Double], Double, Int, Bool)
runJacobi m tol xs p = do
  pokeArray p xs
  (resid, sweeps, converged) <- jacobiIO m tol p
  diagVals <- mapM (\i -> peekElemOff p (i * m + i)) [0 .. m - 1]
  pure (diagVals, resid, sweeps, converged)

-- | In-place cyclic Jacobi diagonalization of the @m x m@ symmetric matrix stored
-- row-major at @p@, converging to the off-diagonal Frobenius-norm tolerance @tol@.
-- Sweeps all off-diagonal pairs, annihilating each in turn by a Givens rotation,
-- until the off-diagonal norm falls below @tol@ or a sweep cap is reached. Returns
-- the final residual, the number of full sweeps performed, and whether the residual
-- actually fell below @tol@ (as opposed to merely exhausting the cap); the diagonal
-- is left in the buffer for the caller to read.
jacobiIO :: Int -> Double -> Ptr Double -> IO (Double, Int, Bool)
jacobiIO m tol p = loop (0 :: Int)
  where
    -- A pivot already this negligible relative to the convergence target would
    -- produce a near-identity rotation; skipping it avoids dividing by a near-zero
    -- apq.
    pivotEps :: Double
    pivotEps = tol * 1.0e-2

    idx :: Int -> Int -> Int
    idx i j = i * m + j

    rd :: Int -> Int -> IO Double
    rd i j = peekElemOff p (idx i j)

    wr :: Int -> Int -> Double -> IO ()
    wr i j = pokeElemOff p (idx i j)

    rotate :: Int -> Int -> IO ()
    rotate q1 q2 = do
      apq <- rd q1 q2
      if abs apq < pivotEps
        then pure ()
        else do
          app <- rd q1 q1
          aqq <- rd q2 q2
          let phi = (aqq - app) / (2 * apq)
              t   = if phi >= 0
                      then 1 / (phi + sqrt (phi * phi + 1))
                      else 1 / (phi - sqrt (phi * phi + 1))
              c   = 1 / sqrt (t * t + 1)
              s   = t * c
          forM_ [0 .. m - 1] $ \i ->
            if i == q1 || i == q2
              then pure ()
              else do
                aip <- rd i q1
                aiq <- rd i q2
                let nip = c * aip - s * aiq
                    niq = s * aip + c * aiq
                wr i q1 nip
                wr q1 i nip
                wr i q2 niq
                wr q2 i niq
          let napp = c * c * app - 2 * s * c * apq + s * s * aqq
              naqq = s * s * app + 2 * s * c * apq + c * c * aqq
          wr q1 q1 napp
          wr q2 q2 naqq
          wr q1 q2 0
          wr q2 q1 0

    sweep :: IO ()
    sweep = forM_ [0 .. m - 2] $ \q1 ->
              forM_ [q1 + 1 .. m - 1] $ \q2 -> rotate q1 q2

    offNorm :: IO Double
    offNorm = do
      vals <- sequence
                [ rd i j | i <- [0 .. m - 1], j <- [0 .. m - 1], i /= j ]
      pure (sqrt (sum (map (\v -> v * v) vals)))

    loop :: Int -> IO (Double, Int, Bool)
    loop k = do
      o <- offNorm
      if o < tol
        then pure (o, k, True)
        else if k >= maxSweeps
               then pure (o, k, False)
               else sweep >> loop (k + 1)

    maxSweeps :: Int
    maxSweeps = 100
