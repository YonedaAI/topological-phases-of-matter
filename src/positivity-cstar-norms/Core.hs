{-|
Module      : Core
Description : Finite-dimensional C*-algebras: matrices, positivity, states, Bloch ball
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

Concrete, dependency-light linear algebra for the finite-dimensional C*-algebras
@M_n(C)@ that model the local building blocks of the quasi-local algebra in
Part~II of the series. We implement:

  * complex matrix arithmetic and the involution @a -> a*@ (conjugate transpose);
  * positivity two ways --- via the eigenvalues of a Hermitian matrix
    (Jacobi diagonalization of the real 2n x 2n embedding), which agrees with
    the closed positive SEMIDEFINITE cone @A_+@ of Theorem~II-A including its
    boundary, and via Cholesky factorization, which only ever certifies the
    strictly stronger positive-DEFINITE case (see 'cholesky' and
    'Proofs.semidefCheck' for the boundary example this distinction turns on);
  * density matrices as states @phi_rho(a) = Tr(rho a)@;
  * the Bloch-ball geometry of qubit states (Example in the state-space section):
    @S(M_2)@ is the closed unit ball, positivity <=> |r| <= 1.

'Matrix' is a genuine, shape-carrying type, not a bare nested list: the only
ways to build one are 'mkMatrix' (checked, total) and 'fromRowsUnsafe' (for
literals whose rectangularity is evident at the call site, e.g.\ the fixed
Pauli matrices below), both of which validate rectangularity, so every
'Matrix' value in scope is guaranteed rectangular with the dimensions it
reports ('matRows', 'matCols'). Binary operations that require matching
shapes ('mmul', 'madd', 'msub') are built on a dimension-checked 'Either'
core ('mmulEither', 'addEither', 'subEither') and fail loudly --- a clear
'error' naming the mismatched shapes --- rather than silently truncating via
@zipWith@ on a shape mismatch, which is what the previous bare-list
representation did. Every matrix actually used anywhere in this package is a
small, statically-fixed square matrix (2x2 or 3x3), so the loud-failure path
is never exercised in practice; it exists so that a future misuse fails
immediately and legibly instead of silently returning a wrong answer.
'approxEqMat' in particular now rejects mismatched shapes outright before
comparing entries, which is what makes 'isHermitian' (defined via
@approxEqMat m (adjoint m)@) correctly reject non-square input instead of
comparing only the overlapping entries of @m@ and @adjoint m@.

Everything is pure @base@ (plus @Data.Complex@), so it compiles under
@-Wall -Wextra -Werror@ without external numerical libraries.
-}
module Core
  ( -- * Matrices over C
    Matrix
  , Vector
  , DimensionError(..)
  , mkMatrix
  , fromRowsUnsafe
  , matRows
  , matCols
  , toRows
  , dim
  , mmul
  , mmulEither
  , madd
  , addEither
  , msub
  , subEither
  , smul
  , adjoint
  , mtrace
  , identity
  , matrixUnit
  , isHermitian
    -- * Spectra and norms
  , hermitianEigenvalues
  , minEigenvalue
  , spectralNorm
    -- * Positivity
  , isPositiveEig
  , cholesky
  , isPositiveDefinite
    -- * States (density matrices)
  , mkDensity
  , isDensity
  , stateEval
  , purity
    -- * Qubit Bloch ball
  , pauliX
  , pauliY
  , pauliZ
  , ident2
  , blochVector
  , densityFromBloch
    -- * Numerical helpers
  , magSq
  , approxEqC
  , approxEqMat
  ) where

import Data.Complex (Complex(..), realPart, imagPart, conjugate)
import Data.List (sort, transpose)
-- NB: 'foldl'' (used below in 'jacobiEigenvalues' and 'cholesky') is taken
-- from the Prelude, which has re-exported it since @base-4.20@ (GHC 9.10);
-- the cabal file's lower bound is set accordingly. An explicit
-- @import Data.List (foldl')@ would be flagged as a redundant import and
-- rejected under @-Werror@ on any base satisfying that bound.

-- | A complex column vector.
type Vector = [Complex Double]

-- | A rectangular matrix over the complex numbers, carrying its validated
-- dimensions. See the module documentation for why this is a checked type
-- rather than a bare nested list.
data Matrix = Matrix
  { matRows :: !Int
    -- ^ Number of rows.
  , matCols :: !Int
    -- ^ Number of columns.
  , toRows  :: [[Complex Double]]
    -- ^ The entries, row-major: the outer list has length 'matRows' and
    -- every inner list has length 'matCols'.
  }

instance Show Matrix where
  show = show . toRows

-- | The ways a 'Matrix' construction or operation can fail: either the input
-- rows were not all the same length, or a binary operation was applied to
-- two matrices whose shapes do not permit it.
data DimensionError
  = NotRectangular
  | ShapeMismatch { dimOp :: String, dimLeft :: (Int, Int), dimRight :: (Int, Int) }
  deriving (Show, Eq)

-- | Validate that a nested list is rectangular before trusting it as a
-- 'Matrix'; @Left NotRectangular@ if the row lengths disagree.
mkMatrix :: [[Complex Double]] -> Either DimensionError Matrix
mkMatrix [] = Right (Matrix 0 0 [])
mkMatrix rs@(r0 : _)
  | all ((== c) . length) rs = Right (Matrix (length rs) c rs)
  | otherwise                = Left NotRectangular
  where
    c = length r0

-- | Build a 'Matrix' from a nested list that is rectangular by construction
-- (a literal constant, or the output of an operation already known to
-- produce a rectangular result). Used only internally in place of
-- re-validating results already reasoned to be rectangular; fails loudly
-- rather than silently if that reasoning was ever wrong.
fromRowsUnsafe :: [[Complex Double]] -> Matrix
fromRowsUnsafe rs = either (error . ("Core.fromRowsUnsafe: " ++) . show) id (mkMatrix rs)

-- | Number of rows of a matrix (every matrix in this package is square, so
-- this doubles as "the" dimension throughout).
dim :: Matrix -> Int
dim = matRows

-- | Matrix multiplication; requires @matCols a == matRows b@. Fails loudly
-- (see the module documentation) rather than silently truncating on a
-- mismatch; 'mmulEither' is the total, checked version.
mmul :: Matrix -> Matrix -> Matrix
mmul a b = either (error . ("Core.mmul: " ++) . show) id (mmulEither a b)

-- | Total, dimension-checked matrix multiplication.
mmulEither :: Matrix -> Matrix -> Either DimensionError Matrix
mmulEither a b
  | matCols a /= matRows b =
      Left (ShapeMismatch "mmul" (matRows a, matCols a) (matRows b, matCols b))
  | otherwise =
      Right (fromRowsUnsafe
        [ [ sum (zipWith (*) row col) | col <- transpose (toRows b) ] | row <- toRows a ])

-- | Entrywise sum; requires matching shapes. Fails loudly on a mismatch;
-- see 'addEither' for the total version.
madd :: Matrix -> Matrix -> Matrix
madd a b = either (error . ("Core.madd: " ++) . show) id (addEither a b)

-- | Total, shape-checked entrywise sum.
addEither :: Matrix -> Matrix -> Either DimensionError Matrix
addEither a b
  | matRows a /= matRows b || matCols a /= matCols b =
      Left (ShapeMismatch "madd" (matRows a, matCols a) (matRows b, matCols b))
  | otherwise = Right (fromRowsUnsafe (zipWith (zipWith (+)) (toRows a) (toRows b)))

-- | Entrywise difference; requires matching shapes. Fails loudly on a
-- mismatch; see 'subEither' for the total version.
msub :: Matrix -> Matrix -> Matrix
msub a b = either (error . ("Core.msub: " ++) . show) id (subEither a b)

-- | Total, shape-checked entrywise difference.
subEither :: Matrix -> Matrix -> Either DimensionError Matrix
subEither a b
  | matRows a /= matRows b || matCols a /= matCols b =
      Left (ShapeMismatch "msub" (matRows a, matCols a) (matRows b, matCols b))
  | otherwise = Right (fromRowsUnsafe (zipWith (zipWith (-)) (toRows a) (toRows b)))

-- | Scalar multiplication (always shape-safe: a unary operation).
smul :: Complex Double -> Matrix -> Matrix
smul s m = fromRowsUnsafe (map (map (s *)) (toRows m))

-- | The C*-involution: conjugate transpose @a -> a*@ (always shape-safe: a
-- unary operation that swaps 'matRows' and 'matCols').
adjoint :: Matrix -> Matrix
adjoint m = fromRowsUnsafe (map (map conjugate) (transpose (toRows m)))

-- | Trace: the sum of the diagonal, as far as it extends (only meaningful,
-- and only ever called here, on square matrices).
mtrace :: Matrix -> Complex Double
mtrace m = sum [ (toRows m !! i) !! i | i <- [0 .. min (matRows m) (matCols m) - 1] ]

-- | The @n x n@ identity matrix.
identity :: Int -> Matrix
identity n =
  fromRowsUnsafe [ [ if i == j then 1 else 0 | j <- [0 .. n - 1] ] | i <- [0 .. n - 1] ]

-- | The matrix unit @E_ij@ in @M_n(C)@ (1 in position @(i,j)@, 0 elsewhere).
matrixUnit :: Int -> Int -> Int -> Matrix
matrixUnit n i j =
  fromRowsUnsafe [ [ if (r, c) == (i, j) then 1 else 0 | c <- [0 .. n - 1] ] | r <- [0 .. n - 1] ]

-- | Squared modulus of a complex number.
magSq :: Complex Double -> Double
magSq z = realPart z * realPart z + imagPart z * imagPart z

-- | Approximate equality of complex numbers.
approxEqC :: Double -> Complex Double -> Complex Double -> Bool
approxEqC tol x y = magSq (x - y) <= tol * tol

-- | Approximate equality of matrices: @False@ immediately on a shape
-- mismatch (rather than silently comparing only the overlapping entries via
-- @zipWith@, which is what a bare nested-list representation does), then
-- entrywise comparison.
approxEqMat :: Double -> Matrix -> Matrix -> Bool
approxEqMat tol a b =
  matRows a == matRows b
    && matCols a == matCols b
    && and (zipWith (\r s -> and (zipWith (approxEqC tol) r s)) (toRows a) (toRows b))

-- | Is the matrix (numerically) Hermitian, @a = a*@? Because 'approxEqMat'
-- now checks shapes first, this also correctly rejects non-square input
-- (its adjoint has swapped dimensions, so the shapes can only agree when
-- @m@ is square).
isHermitian :: Matrix -> Bool
isHermitian m = approxEqMat 1e-9 m (adjoint m)

-- ---------------------------------------------------------------------------
-- Eigenvalues of Hermitian matrices via the real symmetric embedding
-- ---------------------------------------------------------------------------

-- | Embed an @n x n@ complex Hermitian matrix @H = A + iB@ as the real
-- symmetric @2n x 2n@ matrix @[[A,-B],[B,A]]@; each eigenvalue of @H@ appears
-- twice among the eigenvalues of the embedding. Assumes @h@ is square, as it
-- is at every call site (a Hermitian matrix always is).
realEmbed :: Matrix -> [[Double]]
realEmbed h =
  let rows  = toRows h
      aPart = map (map realPart) rows
      bPart = map (map imagPart) rows
      negB  = map (map negate) bPart
      top   = zipWith (++) aPart negB
      bot   = zipWith (++) bPart aPart
  in top ++ bot

-- | Cyclic Jacobi eigenvalue algorithm for a real symmetric matrix.
-- Returns the eigenvalues in ascending order.
jacobiEigenvalues :: [[Double]] -> [Double]
jacobiEigenvalues m0 = sort (diagonalReal (iterate' 0 m0))
  where
    n :: Int
    n = length m0
    maxSweeps :: Int
    maxSweeps = 100
    tol :: Double
    tol = 1e-14
    iterate' :: Int -> [[Double]] -> [[Double]]
    iterate' k m
      | k >= maxSweeps      = m
      | offNorm m < tol     = m
      | otherwise           = iterate' (k + 1) (sweep m)
    sweep :: [[Double]] -> [[Double]]
    sweep m = foldl' rotateAt m [ (p, q) | p <- [0 .. n - 1], q <- [p + 1 .. n - 1] ]

-- | Off-diagonal Frobenius norm of a real matrix.
offNorm :: [[Double]] -> Double
offNorm m =
  sqrt (sum [ ((m !! i) !! j) ^ (2 :: Int)
            | i <- [0 .. length m - 1], j <- [0 .. length m - 1], i /= j ])

-- | Diagonal of a real matrix.
diagonalReal :: [[Double]] -> [Double]
diagonalReal m = [ (m !! i) !! i | i <- [0 .. length m - 1] ]

-- | One Jacobi rotation zeroing the @(p,q)@ off-diagonal entry, applied as
-- @A -> J^T A J@.
rotateAt :: [[Double]] -> (Int, Int) -> [[Double]]
rotateAt m (p, q)
  | abs apq < 1e-300 = m
  | otherwise        = matMulR (transpose j) (matMulR m j)
  where
    n :: Int
    n = length m
    apq, app, aqq, theta, t, c, s :: Double
    apq   = (m !! p) !! q
    app   = (m !! p) !! p
    aqq   = (m !! q) !! q
    theta = (aqq - app) / (2 * apq)
    t     = if theta == 0
              then 1
              else signum theta / (abs theta + sqrt (theta * theta + 1))
    c     = 1 / sqrt (t * t + 1)
    s     = t * c
    j     = [ [ rot r col | col <- [0 .. n - 1] ] | r <- [0 .. n - 1] ]
    rot :: Int -> Int -> Double
    rot r col
      | (r, col) == (p, p) = c
      | (r, col) == (q, q) = c
      | (r, col) == (p, q) = s
      | (r, col) == (q, p) = -s
      | r == col           = 1
      | otherwise          = 0

-- | Real matrix multiplication (helper for the Jacobi routine).
matMulR :: [[Double]] -> [[Double]] -> [[Double]]
matMulR a b = [ [ sum (zipWith (*) row col) | col <- transpose b ] | row <- a ]

-- | Eigenvalues of a Hermitian matrix, ascending, with correct multiplicity.
hermitianEigenvalues :: Matrix -> [Double]
hermitianEigenvalues = everyOther . jacobiEigenvalues . realEmbed
  where
    everyOther :: [a] -> [a]
    everyOther (x : _ : xs) = x : everyOther xs
    everyOther xs           = xs

-- | Smallest eigenvalue of a Hermitian matrix.
minEigenvalue :: Matrix -> Double
minEigenvalue h = case hermitianEigenvalues h of
  [] -> 0
  es -> minimum es

-- | Operator (spectral) norm: the largest singular value,
-- @||a|| = sqrt(lambda_max(a* a))@.
spectralNorm :: Matrix -> Double
spectralNorm a =
  let evs = hermitianEigenvalues (adjoint a `mmul` a)
  in sqrt (maximum (0 : evs))

-- ---------------------------------------------------------------------------
-- Positivity
-- ---------------------------------------------------------------------------

-- | Positivity via eigenvalues: a Hermitian matrix is positive semidefinite
-- iff its smallest eigenvalue is nonnegative (up to tolerance). This is the
-- test that agrees with the closed positive cone @A_+@ of Theorem~II-A,
-- including boundary (singular positive) elements such as @diag(1,0)@.
isPositiveEig :: Matrix -> Bool
isPositiveEig h = isHermitian h && minEigenvalue h >= -1e-7

-- | Cholesky factorization @m = L L*@ with @L@ lower triangular and positive
-- real diagonal; returns @Nothing@ exactly when @m@ is not positive
-- DEFINITE. This is strictly stronger than membership in the closed
-- positive semidefinite cone @A_+@ of Theorem~II-A: a positive but singular
-- matrix such as @diag(1,0)@ lies in @A_+@ (indeed 'isPositiveEig' accepts
-- it) but is rejected here, because its second pivot is exactly zero. Use
-- 'isPositiveEig' when semidefinite (closed-cone) positivity is what is
-- meant; 'cholesky'\/'isPositiveDefinite' certify the strictly interior
-- notion.
cholesky :: Matrix -> Maybe Matrix
cholesky m
  | matRows m /= matCols m = Nothing
  | not (isHermitian m)    = Nothing
  | otherwise              = build 0 (fromRowsUnsafe (replicate n (replicate n 0)))
  where
    n :: Int
    n = matRows m
    build :: Int -> Matrix -> Maybe Matrix
    build j l
      | j >= n    = Just l
      | d <= 1e-12 = Nothing
      | otherwise = build (j + 1) lColumn
      where
        d :: Double
        d = realPart ((toRows m !! j) !! j) - sum [ magSq ((toRows l !! j) !! k) | k <- [0 .. j - 1] ]
        ljj :: Complex Double
        ljj = sqrt d :+ 0
        lDiag :: Matrix
        lDiag = setEntry l j j ljj
        lColumn :: Matrix
        lColumn = foldl' fillRow lDiag [ j + 1 .. n - 1 ]
        fillRow :: Matrix -> Int -> Matrix
        fillRow lacc i =
          let s   = (toRows m !! i) !! j
                    - sum [ (toRows lacc !! i !! k) * conjugate (toRows lacc !! j !! k) | k <- [0 .. j - 1] ]
              lij = s / ljj
          in setEntry lacc i j lij

-- | Set a single entry of a matrix (used only inside 'cholesky', where the
-- matrix is already known to be square; uses 'matCols' and 'matRows'
-- separately rather than assuming squareness a second time).
setEntry :: Matrix -> Int -> Int -> Complex Double -> Matrix
setEntry m i j x =
  fromRowsUnsafe
    [ [ if (r, c) == (i, j) then x else (toRows m !! r) !! c | c <- [0 .. matCols m - 1] ]
    | r <- [0 .. matRows m - 1] ]

-- | Positive definiteness via successful Cholesky factorization.
isPositiveDefinite :: Matrix -> Bool
isPositiveDefinite m = case cholesky m of
  Just _  -> True
  Nothing -> False

-- ---------------------------------------------------------------------------
-- States as density matrices
-- ---------------------------------------------------------------------------

-- | Build a density matrix (state) from an arbitrary matrix @M@ via
-- @rho = M M* / Tr(M M*)@; falls back to the maximally mixed state if @M@ is
-- numerically zero. Total on every square input, and always lands in
-- @St(M_n)@ (checked by 'Properties.prop_mkDensityValid').
mkDensity :: Matrix -> Matrix
mkDensity mm =
  let p  = mm `mmul` adjoint mm
      tr = realPart (mtrace p)
  in if tr <= 1e-12
       then smul (1 / fromIntegral (dim mm) :+ 0) (identity (dim mm))
       else smul (1 / tr :+ 0) p

-- | Is the matrix a valid density matrix: Hermitian, positive semidefinite,
-- unit trace?
isDensity :: Matrix -> Bool
isDensity rho =
  isHermitian rho
    && isPositiveEig rho
    && approxEqC 1e-7 (mtrace rho) 1

-- | Evaluate the state @phi_rho(a) = Tr(rho a)@.
stateEval :: Matrix -> Matrix -> Complex Double
stateEval rho a = mtrace (rho `mmul` a)

-- | Purity @Tr(rho^2)@ of a density matrix (real part).
purity :: Matrix -> Double
purity rho = realPart (mtrace (rho `mmul` rho))

-- ---------------------------------------------------------------------------
-- Qubit Bloch ball
-- ---------------------------------------------------------------------------

-- | Pauli @sigma_x@.
pauliX :: Matrix
pauliX = fromRowsUnsafe [ [0, 1], [1, 0] ]

-- | Pauli @sigma_y@.
pauliY :: Matrix
pauliY = fromRowsUnsafe [ [0, 0 :+ (-1)], [0 :+ 1, 0] ]

-- | Pauli @sigma_z@.
pauliZ :: Matrix
pauliZ = fromRowsUnsafe [ [1, 0], [0, -1] ]

-- | The @2 x 2@ identity.
ident2 :: Matrix
ident2 = identity 2

-- | Bloch vector @r = (Tr(rho sigma_x), Tr(rho sigma_y), Tr(rho sigma_z))@.
blochVector :: Matrix -> (Double, Double, Double)
blochVector rho =
  ( realPart (stateEval rho pauliX)
  , realPart (stateEval rho pauliY)
  , realPart (stateEval rho pauliZ) )

-- | Density matrix of a qubit from its Bloch vector: @rho = (I + r . sigma)/2@.
densityFromBloch :: (Double, Double, Double) -> Matrix
densityFromBloch (x, y, z) =
  let rSigma = madd (madd (smul (x :+ 0) pauliX) (smul (y :+ 0) pauliY))
                    (smul (z :+ 0) pauliZ)
  in smul (0.5 :+ 0) (madd ident2 rSigma)
