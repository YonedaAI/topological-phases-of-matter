{-|
Module      : CrossedProduct
Description : Finite-level model of the Bellissard crossed-product disorder algebra
Copyright   : (c) Matthew Long, 2026
License     : MIT
Maintainer  : matthew@yonedaai.com
Stability   : experimental

A finite, fully computable instance of the crossed-product construction and its
functoriality in finite quotients (\Cref{thm:crossed}, Theorem~II-C,
"Crossed-product disorder algebra"). We do not model the full disorder hull
@Omega = Q^(Z^d)@; instead we fix a finite ambient group @G = Z\/bigN@ (standing
in for the translation group @T@) and, for each divisor @n@ of @bigN@, let @G@
act on @X_n = Z\/n@ by translation reduced modulo @n@ --- exactly the paper's
finite quotients of the disorder hull (\Cref{prop:hullAF}), with the shift
action descending to @X_n@ because reduction mod @n@ is a group homomorphism
@Z\/bigN -> Z\/n@ whenever @n@ divides @bigN@.

The finite crossed product @C(X_n) \\rtimes G@ is represented as @bigN@
"Fourier components," each a function on @X_n@ (a length-@n@ list); this is the
standard twisted-convolution presentation of a discrete-group crossed product,
specialized to a finite group acting on a finite set, so no completion is
needed and the algebra is already finite-dimensional (dimension @n * bigN@).
For @n' | n@ (both dividing @bigN@) the periodization map 'includeXP' is
exactly the pullback @p^* : C(X_n') -> C(X_n)@ along the equivariant quotient
@p@ of \Cref{thm:crossed}'s proof, extended group-component-wise to the
crossed product; 'restrictXP' is a one-sided inverse witnessing that the
induced map on crossed products is injective, and 'diagEmbed' exhibits
@C(X_n)@ itself (\Cref{prop:hullAF}) as the sub-algebra of elements supported
at the trivial group element.

'XP' is a genuine, shape-carrying type, exactly mirroring @Core.Matrix@: the
only ways to build one are 'mkXP' (checked, total) and 'xpUnsafe' (for values
rectangular by construction, e.g.\ 'xpUnit' below), both validating
rectangularity, so every 'XP' value in scope is guaranteed rectangular with
the shape it reports ('xpGroupSize', the number of Fourier components;
'xpLevel', the length of each). Operations that require a specific shape
('xpMul', 'xpAdjoint', 'includeXP') or matching shapes ('xpAdd') check it and
fail loudly --- a clear 'error' naming the shapes involved --- rather than
silently truncating via @zipWith@ or crashing on an unhelpful out-of-bounds
@(!!)@, which is what a bare nested-list representation does; 'xpMulEither',
'xpAdjointEither', and 'xpAddEither' are the total, 'Either'-returning cores
underneath. Every crossed-product element actually used in this package has
a small, statically-fixed shape, so the loud-failure path is never exercised
in practice.
-}
module CrossedProduct
  ( XP
  , XPShapeError(..)
  , mkXP
  , xpUnsafe
  , xpGroupSize
  , xpLevel
  , xpComps
  , xpUnit
  , xpZero
  , xpAdd
  , xpAddEither
  , xpScale
  , xpMul
  , xpMulEither
  , xpAdjoint
  , xpAdjointEither
  , xpApprox
  , includeXP
  , restrictXP
  , diagEmbed
  ) where

import Data.Complex (Complex(..), conjugate)

-- | An element of the finite crossed product @C(Z\/n) \\rtimes (Z\/bigN)@,
-- carrying its validated shape: 'xpGroupSize' Fourier components indexed by
-- the acting group @Z\/bigN@, each a function on @Z\/n@ of length 'xpLevel'.
-- See the module documentation for why this is a checked type rather than a
-- bare nested list.
data XP = XP
  { xpGroupSize :: !Int
    -- ^ @bigN@: the number of Fourier components (the ambient group size).
  , xpLevel     :: !Int
    -- ^ @n@: the length of each Fourier component (the level).
  , xpComps     :: [[Complex Double]]
    -- ^ The components, outer list of length 'xpGroupSize', each inner list
    -- of length 'xpLevel'.
  }

instance Show XP where
  show = show . xpComps

-- | The ways constructing or operating on an 'XP' can fail: either the input
-- rows were not all the same length, or an operation requiring a specific
-- shape (or matching shapes) was given one that does not fit.
data XPShapeError
  = XPNotRectangular
  | XPShapeMismatch { xpOp :: String, xpExpected :: (Int, Int), xpGot :: (Int, Int) }
  deriving (Show, Eq)

-- | Validate that a nested list is rectangular before trusting it as an
-- 'XP'; @Left XPNotRectangular@ if the component lengths disagree.
mkXP :: [[Complex Double]] -> Either XPShapeError XP
mkXP [] = Right (XP 0 0 [])
mkXP rs@(r0 : _)
  | all ((== c) . length) rs = Right (XP (length rs) c rs)
  | otherwise                = Left XPNotRectangular
  where
    c = length r0

-- | Build an 'XP' from a nested list that is rectangular by construction
-- (a literal constant, or the output of an operation already known to
-- produce a rectangular result). Used only internally in place of
-- re-validating results already reasoned to be rectangular; fails loudly
-- rather than silently if that reasoning was ever wrong.
xpUnsafe :: [[Complex Double]] -> XP
xpUnsafe rs = either (error . ("CrossedProduct.xpUnsafe: " ++) . show) id (mkXP rs)

-- | The multiplicative unit @1_g(x) = [g == 0]@: supported entirely on the
-- trivial group element, constant @1@ there.
xpUnit :: Int -> Int -> XP
xpUnit n bigN =
  xpUnsafe [ [ if g == 0 then 1 else 0 | _ <- [0 .. n - 1] ] | g <- [0 .. bigN - 1] ]

-- | The additive zero.
xpZero :: Int -> Int -> XP
xpZero n bigN = xpUnsafe [ replicate n 0 | _ <- [0 .. bigN - 1] ]

-- | Entrywise sum; requires matching shapes. Fails loudly (see the module
-- documentation) rather than silently truncating via @zipWith@ on a
-- mismatch; 'xpAddEither' is the total, checked version.
xpAdd :: XP -> XP -> XP
xpAdd a b = either (error . ("CrossedProduct.xpAdd: " ++) . show) id (xpAddEither a b)

-- | Total, shape-checked entrywise sum.
xpAddEither :: XP -> XP -> Either XPShapeError XP
xpAddEither a b
  | xpGroupSize a /= xpGroupSize b || xpLevel a /= xpLevel b =
      Left (XPShapeMismatch "xpAdd" (xpGroupSize a, xpLevel a) (xpGroupSize b, xpLevel b))
  | otherwise = Right (xpUnsafe (zipWith (zipWith (+)) (xpComps a) (xpComps b)))

-- | Scalar multiplication (always shape-safe: a unary operation).
xpScale :: Complex Double -> XP -> XP
xpScale s a = xpUnsafe (map (map (s *)) (xpComps a))

-- | Twisted convolution product on @C(Z\/n) \\rtimes (Z\/bigN)@, with the group
-- acting on functions by @(alpha_h f)(x) = f((x - h) \`mod\` n)@:
--
-- > (a * b)_g(x) = sum_h a_h(x) * b_{g - h}((x - h) `mod` n)
--
-- the standard twisted-convolution product of a group crossed product,
-- specialized to the finite group @Z\/bigN@ acting on @Z\/n@. Requires both
-- arguments to actually have shape @(bigN, n)@; fails loudly (naming the
-- shapes involved) rather than crashing on an unhelpful out-of-bounds index
-- if they do not. 'xpMulEither' is the total, checked version.
xpMul :: Int -> Int -> XP -> XP -> XP
xpMul n bigN as bs = either (error . ("CrossedProduct.xpMul: " ++) . show) id (xpMulEither n bigN as bs)

-- | Total, shape-checked version of 'xpMul'.
xpMulEither :: Int -> Int -> XP -> XP -> Either XPShapeError XP
xpMulEither n bigN as bs
  | xpGroupSize as /= bigN || xpLevel as /= n =
      Left (XPShapeMismatch "xpMul (left argument)" (bigN, n) (xpGroupSize as, xpLevel as))
  | xpGroupSize bs /= bigN || xpLevel bs /= n =
      Left (XPShapeMismatch "xpMul (right argument)" (bigN, n) (xpGroupSize bs, xpLevel bs))
  | otherwise =
      Right (xpUnsafe
        [ [ sum [ (csAs !! h !! x) * (csBs !! ((g - h) `mod` bigN) !! ((x - h) `mod` n))
                | h <- [0 .. bigN - 1] ]
          | x <- [0 .. n - 1] ]
        | g <- [0 .. bigN - 1] ])
  where
    csAs = xpComps as
    csBs = xpComps bs

-- | The involution @(a^*)_g(x) = conj(a_{-g}((x - g) \`mod\` n))@, making
-- @C(Z\/n) \\rtimes (Z\/bigN)@ a @*@-algebra. Requires @as@ to actually have
-- shape @(bigN, n)@; fails loudly rather than crashing on a mismatch.
-- 'xpAdjointEither' is the total, checked version.
xpAdjoint :: Int -> Int -> XP -> XP
xpAdjoint n bigN as = either (error . ("CrossedProduct.xpAdjoint: " ++) . show) id (xpAdjointEither n bigN as)

-- | Total, shape-checked version of 'xpAdjoint'.
xpAdjointEither :: Int -> Int -> XP -> Either XPShapeError XP
xpAdjointEither n bigN as
  | xpGroupSize as /= bigN || xpLevel as /= n =
      Left (XPShapeMismatch "xpAdjoint" (bigN, n) (xpGroupSize as, xpLevel as))
  | otherwise =
      Right (xpUnsafe
        [ [ conjugate (cs !! ((-g) `mod` bigN) !! ((x - g) `mod` n))
          | x <- [0 .. n - 1] ]
        | g <- [0 .. bigN - 1] ])
  where
    cs = xpComps as

-- | Approximate equality: @False@ immediately on a shape mismatch (rather
-- than silently comparing only the overlapping entries via @zipWith@),
-- then entrywise comparison.
xpApprox :: Double -> XP -> XP -> Bool
xpApprox tol a b =
  xpGroupSize a == xpGroupSize b
    && xpLevel a == xpLevel b
    && and (zipWith (\r s -> and (zipWith close r s)) (xpComps a) (xpComps b))
  where
    close :: Complex Double -> Complex Double -> Bool
    close x y = let d = x - y in magSq d <= tol * tol
    magSq :: Complex Double -> Double
    magSq (re :+ im) = re * re + im * im

-- | Periodization @p^*@: include @C(Z\/n') \\rtimes G@ into @C(Z\/n) \\rtimes G@
-- for @n' | n@ (both dividing the ambient @bigN@), by precomposing each
-- Fourier component with reduction mod @n'@. This is the finite-level
-- instance of the @*@-monomorphism @p^* : C(Omega') -> C(Omega)@ from the
-- proof of \Cref{thm:crossed}, extended group-component-wise; because
-- @n' | n@ implies @(y \`mod\` n) \`mod\` n' = y \`mod\` n'@ for every integer
-- @y@, this extension is genuinely a @*@-homomorphism of the crossed
-- products (checked by 'Properties.prop_xpInclusionHom' and
-- 'Proofs.xpHomCheck'). Requires @as@ to actually have level @n'@; fails
-- loudly rather than crashing on a mismatch.
includeXP :: Int -> Int -> XP -> XP
includeXP nPrime n as
  | xpLevel as /= nPrime =
      error ("CrossedProduct.includeXP: expected level " ++ show nPrime
             ++ ", got " ++ show (xpLevel as))
  | otherwise =
      xpUnsafe (map (\f -> [ f !! (x `mod` nPrime) | x <- [0 .. n - 1] ]) (xpComps as))

-- | One-sided inverse of 'includeXP': evaluate at the representatives
-- @0, .., n' - 1@, which 'includeXP' fixes pointwise (they already satisfy
-- @x \`mod\` n' = x@). Witnesses that the induced map on crossed products is
-- injective.
restrictXP :: Int -> XP -> XP
restrictXP nPrime as = xpUnsafe (map (take nPrime) (xpComps as))

-- | Embed a function on @X_n@ (an element of @C(X_n)@) as the "diagonal"
-- crossed-product element supported at the trivial group element only; the
-- image is closed under 'xpMul', which restricts there to ordinary pointwise
-- multiplication of functions (\Cref{prop:hullAF}: @C(Omega)@ sits inside the
-- crossed product this way).
diagEmbed :: Int -> [Complex Double] -> XP
diagEmbed bigN f = xpUnsafe (f : replicate (bigN - 1) (replicate (length f) 0))
