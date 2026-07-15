{-|
Module      : Stabilizer
Description : Exact stabilizer engine for the 1D cluster-state Z2xZ2 SPT (Proposition "Cluster-state string order")
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

An exact stabilizer-formalism engine over the binary symplectic (check-matrix)
representation of Pauli operators, with i-power phase tracking. Pauli operators
are @i^phase (X-part)(Z-part)@; expectation values in a stabilizer state are
computed by testing membership in the stabilizer group via Gaussian elimination
over F2. The module builds the 1D cluster state, evaluates the SPT string-order
parameter S(a,b), and computes its exact degradation under a symmetry-breaking
on-site rotation U(theta) by expanding U(theta)^* S U(theta) into Pauli terms
and summing their stabilizer expectations (no closed-form shortcut). This
realizes Proposition (Cluster-state string order) of Part V
(bordism-realizability.tex:493-537).

'Pauli' is exported abstractly (no constructor, no field accessors): every
value in scope outside this module is built through 'pauliI', 'single',
'multPauli', or 'productPauli', each of which either is total by construction
or validates its inputs, so a caller cannot assemble a Pauli operator with
mismatched X/Z vector lengths. Qubit sites are validated in 'single' (@0 <= s <
n@) and Pauli letters are the closed 'PauliLetter' ADT rather than a bare
'Char', so there is no "unknown letter" partial case. 'multPauli' and
'anticommutes' reject mismatched operand lengths instead of silently
truncating via 'zipWith'. The SPT string window @(n, a, b)@ of Proposition
(Cluster-state string order) is likewise only constructible, as a
'StringWindow', through the validating smart constructor 'mkStringWindow',
which enforces the paper's precondition @a < b@, @b - a@ even
(bordism-realizability.tex:493-497), together with valid finite-chain
endpoints @0 <= a@, @b <= n-1@.
-}
module Stabilizer
  ( Pauli
  , PauliLetter(..)
  , pauliI
  , single
  , multPauli
  , negatePauli
  , productPauli
  , clusterGenerators
  , anticommutes
  , expectation
  , StringWindow
  , swN
  , swA
  , swB
  , mkStringWindow
  , stringOp
  , stringOrder
  , stringOrderRotated
  , numX
  ) where

-- | A single-qubit Pauli letter: a type-safe alternative to a bare 'Char', so
--   'single' below is total (no "unknown letter" fallback is possible, unlike
--   the previous @Char@-plus-@error@ encoding).
data PauliLetter = LI | LX | LY | LZ
  deriving (Eq, Show)

-- | An @n@-qubit Pauli operator @i^pPhase * (prod_j X_j^{x_j}) (prod_j Z_j^{z_j})@,
--   with @pX@, @pZ@ the length-@n@ X- and Z-exponent bit vectors and @pPhase@ the
--   exponent of @i@ taken modulo 4. The constructor and fields are kept
--   internal to this module (see the module description above); build values
--   only via 'pauliI', 'single', 'multPauli', or 'productPauli'.
data Pauli = Pauli
  { pX     :: [Bool]
  , pZ     :: [Bool]
  , pPhase :: Int
  } deriving (Eq, Show)

-- | Identity on @n@ qubits.
pauliI :: Int -> Pauli
pauliI n = Pauli (replicate n False) (replicate n False) 0

-- | Set the @i@-th entry of a list to @v@ (0-indexed).
setAt :: Int -> a -> [a] -> [a]
setAt i v xs = [ if j == i then v else x | (j, x) <- zip [0 ..] xs ]

-- | Single-site Pauli @l@ at site @s@ on @n@ qubits. Total over 'PauliLetter';
--   raises a clear error if @s@ is out of range. (Previously, an out-of-range
--   @s@ made 'setAt' a silent no-op, so @single n c s@ quietly returned the
--   identity instead of signalling the mistake.)
single :: Int -> PauliLetter -> Int -> Pauli
single n l s
  | s < 0 || s >= n =
      error ("single: site " ++ show s ++ " out of range [0," ++ show n ++ ")")
  | otherwise = case l of
      LI -> pauliI n
      LX -> Pauli (setAt s True zeros) zeros 0
      LZ -> Pauli zeros (setAt s True zeros) 0
      LY -> Pauli (setAt s True zeros) (setAt s True zeros) 1  -- Y = i X Z
  where zeros = replicate n False

-- | Product of two Paulis with exact phase tracking. Reordering @Z^{z1} X^{x2}@
--   contributes @(-1)^{z1 . x2} = i^{2 (z1 . x2)}@. Requires both operands to
--   act on the same number of qubits and raises a clear error otherwise;
--   mismatched lengths previously made 'zipWith' silently truncate to the
--   shorter operand.
multPauli :: Pauli -> Pauli -> Pauli
multPauli (Pauli x1 z1 p1) (Pauli x2 z2 p2)
  | length x1 /= length x2 || length z1 /= length z2 =
      error "multPauli: mismatched qubit counts between operands"
  | otherwise =
      Pauli (zipWith (/=) x1 x2) (zipWith (/=) z1 z2)
            ((p1 + p2 + 2 * cross) `mod` 4)
  where
    cross = length (filter id (zipWith (&&) z1 x2))

-- | Multiply a Pauli by @-1@ (add @i^2@).
negatePauli :: Pauli -> Pauli
negatePauli (Pauli x z p) = Pauli x z ((p + 2) `mod` 4)

-- | Ordered product of a list of Paulis on @n@ qubits.
productPauli :: Int -> [Pauli] -> Pauli
productPauli n = foldl multPauli (pauliI n)

-- | Stabilizer generators of the open-boundary 1D cluster state on @n@ qubits:
--   bulk generators @K_j = Z_{j-1} X_j Z_{j+1}@ and the two boundary generators.
clusterGenerators :: Int -> [Pauli]
clusterGenerators n
  | n < 2     = error "clusterGenerators: need n >= 2"
  | otherwise = [ gen j | j <- [0 .. n - 1] ]
  where
    gen j
      | j == 0     = multPauli (single n LX 0) (single n LZ 1)
      | j == n - 1 = multPauli (single n LZ (n - 2)) (single n LX (n - 1))
      | otherwise  = productPauli n [ single n LZ (j - 1)
                                    , single n LX j
                                    , single n LZ (j + 1) ]

-- | Do two Paulis anticommute? (Odd symplectic inner product.) Requires both
--   operands to act on the same number of qubits, for the same reason as
--   'multPauli'.
anticommutes :: Pauli -> Pauli -> Bool
anticommutes (Pauli x1 z1 _) (Pauli x2 z2 _)
  | length x1 /= length x2 || length z1 /= length z2 =
      error "anticommutes: mismatched qubit counts between operands"
  | otherwise = odd sp
  where
    sp = length (filter id (zipWith (&&) x1 z2))
       + length (filter id (zipWith (&&) z1 x2))

-- | F2 vector sum (elementwise XOR).
xorV :: [Bool] -> [Bool] -> [Bool]
xorV = zipWith (/=)

-- | Symmetric difference of two index sets (F2 addition of coefficient supports).
symDiff :: [Int] -> [Int] -> [Int]
symDiff a b = [ x | x <- a, x `notElem` b ] ++ [ x | x <- b, x `notElem` a ]

-- | Index of the first @True@ entry, if any.
firstPivot :: [Bool] -> Maybe Int
firstPivot v = case [ i | (i, True) <- zip [0 ..] v ] of
  (i : _) -> Just i
  []      -> Nothing

-- | Incrementally build a row-reduced F2 basis with provenance. Each basis entry
--   is @(pivotColumn, vector, originalIndices)@ where the XOR of the generators at
--   @originalIndices@ equals @vector@.
addRow :: [(Int, [Bool], [Int])] -> (Int, [Bool]) -> [(Int, [Bool], [Int])]
addRow basis (i, v0) =
  let (v, idx) = foldl step (v0, [i]) basis
  in case firstPivot v of
       Just piv -> basis ++ [(piv, v, idx)]
       Nothing  -> basis
  where
    step (vv, ii) (c, bv, bidx)
      | vv !! c   = (xorV vv bv, symDiff ii bidx)
      | otherwise = (vv, ii)

-- | Reduce a target vector against a basis, returning the residual and the
--   provenance index set of the basis rows used.
reduceTarget :: [(Int, [Bool], [Int])] -> [Bool] -> ([Bool], [Int])
reduceTarget basis t0 = foldl step (t0, []) basis
  where
    step (vv, ii) (c, bv, bidx)
      | vv !! c   = (xorV vv bv, symDiff ii bidx)
      | otherwise = (vv, ii)

-- | Solve @sum_{i in S} rows!!i = target@ over F2; return the index set @S@ if solvable.
solveF2 :: [[Bool]] -> [Bool] -> Maybe [Int]
solveF2 rows target =
  let basis      = foldl addRow [] (zip [0 ..] rows)
      (res, idx) = reduceTarget basis target
  in if all not res then Just idx else Nothing

-- | Express a Pauli's @(x || z)@ symplectic vector in the span of the generators.
solveSubset :: [Pauli] -> Pauli -> Maybe [Int]
solveSubset gens p = solveF2 [ pX g ++ pZ g | g <- gens ] (pX p ++ pZ p)

-- | Pick the list elements at the given indices.
pick :: [a] -> [Int] -> [a]
pick xs is = [ xs !! i | i <- is ]

-- | Compare two Paulis with the same @(x, z)@ pattern: @+1@ if equal, @-1@ if
--   they differ by an overall sign, @0@ otherwise (non-Hermitian mismatch).
comparePhase :: Pauli -> Pauli -> Int
comparePhase gT p = case (pPhase p - pPhase gT) `mod` 4 of
  0 -> 1
  2 -> -1
  _ -> 0

-- | Expectation @<C| P |C>@ of a Pauli @P@ in the stabilizer state defined by
--   @gens@: @+1@ if @P@ is in the stabilizer group, @-1@ if @-P@ is, else @0@.
expectation :: [Pauli] -> Pauli -> Int
expectation gens p
  | any (anticommutes p) gens = 0
  | otherwise = case solveSubset gens p of
      Nothing -> 0
      Just t  -> comparePhase (productPauli n (pick gens t)) p
  where
    n = length (pX p)

-- | A validated window @(n, a, b)@ for the SPT string operator @S(a,b)@ of
--   Proposition (Cluster-state string order) (bordism-realizability.tex:493-497):
--   @0 <= a < b <= n-1@ and @b - a@ even. The constructor is kept internal;
--   build values only via 'mkStringWindow', so every function below that
--   consumes a 'StringWindow' is automatically applied only to a window
--   satisfying the paper's precondition.
data StringWindow = StringWindow
  { swN :: !Int
  , swA :: !Int
  , swB :: !Int
  } deriving (Eq, Show)

-- | Smart constructor: @Just@ the window iff @n >= 2@, @0 <= a < b <= n-1@,
--   and @b - a@ is even (the paper's precondition "fix @a<b@ with @b-a@
--   even", specialized to a finite, open-boundary chain of @n@ qubits);
--   @Nothing@ otherwise.
mkStringWindow :: Int -> Int -> Int -> Maybe StringWindow
mkStringWindow n a b
  | n >= 2 && 0 <= a && a < b && b <= n - 1 && even (b - a) = Just (StringWindow n a b)
  | otherwise = Nothing

-- | The X-sites of the SPT string operator @S(a,b)@: @a+1, a+3, ..., b-1@.
xSites :: StringWindow -> [Int]
xSites (StringWindow _ a b) = [ a + 1, a + 3 .. b - 1 ]

-- | Number of X factors in @S(a,b)@, equal to @(b-a)/2@.
numX :: StringWindow -> Int
numX = length . xSites

-- | SPT string operator @S(a,b) = Z_a X_{a+1} X_{a+3} ... X_{b-1} Z_b@ on @n@ qubits.
--   It equals the product @K_{a+1} K_{a+3} ... K_{b-1}@ of alternate cluster
--   stabilizers, hence lies in the stabilizer group.
stringOp :: StringWindow -> Pauli
stringOp w@(StringWindow n a b) =
  productPauli n ( single n LZ a
                 : [ single n LX s | s <- xSites w ]
                 ++ [ single n LZ b ] )

-- | The cluster-state string order parameter @<C| S(a,b) |C>@ (equals @+1@).
stringOrder :: StringWindow -> Int
stringOrder w@(StringWindow n _ _) = expectation (clusterGenerators n) (stringOp w)

-- | Exact string order under the symmetry-breaking rotation
--   @U(theta) = prod_j exp(-i theta Z_j / 2)@:
--   @<C| U(theta)^* S(a,b) U(theta) |C>@. Since @U^* X_s U = cos(theta) X_s - sin(theta) Y_s@
--   and @U^* Z U = Z@, the rotated string expands into @2^m@ Pauli terms whose exact
--   stabilizer expectations are summed. The result equals @cos(theta)^m@.
stringOrderRotated :: StringWindow -> Double -> Double
stringOrderRotated w@(StringWindow n a b) theta =
  sum [ coeff cs * fromIntegral (expectation gens (opOf cs)) | cs <- choices ]
  where
    gens    = clusterGenerators n
    sites   = xSites w
    choices = mapM (const [True, False]) sites  -- True = X (cos), False = Y (-sin)
    coeff cs = product [ if c then cos theta else negate (sin theta) | c <- cs ]
    opOf cs  = productPauli n ( single n LZ a
                              : [ single n (if c then LX else LY) s | (c, s) <- zip cs sites ]
                              ++ [ single n LZ b ] )
