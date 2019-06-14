require 'concurrent'
require 'minitest/autorun'

=begin
Implement the following Haskell snippet
ghci> (*) <$> Just 2 <*> Just 8
Just 16
ghci> (++) <$> Just "klingon" <*> Nothing
Nothing
=end

class TestJustProduct < Minitest::Test

  def setup
    @just_a = Concurrent::Maybe.just(2)
    @just_b = Concurrent::Maybe.just(8)
    @just_result = Concurrent::Maybe.from do
      (-> (x, y) { x * y }).curry.(@just_a).(@just_b)
    end
    @just_str = Concurrent::Maybe.just("klingon")
    @nothing = Concurrent::Maybe.nothing
    @nothing_result = Concurrent::Maybe.from do
      (-> (x, y) { x + y }).curry.(@just_str).(@nothing)
    end
  end

  def test_just_a
    assert_equal true, @just_a.just?
    assert_equal 2, @just_a.value
    assert_equal false, @just_a.nothing?
    assert_equal Concurrent::Maybe::NONE, @just_a.reason
    assert_equal @just_a.value, @just_a.or(1)
  end

  # Failure on Just x + Just y
  def test_just_result
    assert_equal false, @just_result.just?
    assert_equal Concurrent::Maybe::NONE, @just_result.value
    assert_equal true, @just_result.nothing?
    assert_equal NoMethodError, @just_result.reason.class
    assert_equal 1, @just_result.or(1)
  end

  def test_nothing
    assert_equal false, @nothing.just?
    assert_equal Concurrent::Maybe::NONE, @nothing.value
    assert_equal true, @nothing.nothing?
    assert_equal StandardError, @nothing.reason.class
    assert_equal 1, @nothing.or(1)
  end

  # Failure on Just x + Nothing
  def test_nothing_result
    assert_equal false, @nothing_result.just?
    assert_equal Concurrent::Maybe::NONE, @nothing_result.value
    assert_equal true, @nothing_result.nothing?
    assert_equal NoMethodError, @nothing_result.reason.class
    assert_equal 1, @nothing_result.or(1)
  end

  def test_misc
    assert_raises NoMethodError do
      [@just_a, @just_b].inject(&:+)
    end
    assert_equal 10, [@just_a, @just_b].map(&:value).inject(&:+)
    assert_raises NoMethodError do
      [@just_a, Concurrent::Maybe::NONE].map(&:value).inject(&:+)
    end
  end
end

=begin
fmap :: (a -> b) -> f a -> f b

instance Functor Maybe where
    fmap f (Just x) = Just (f x)
    fmap f Nothing = Nothing

Functor laws:
- fmap id = id
- fmap (f . g) = fmap f . fmap g
=end

def fmap(fproc, maybe)
  return maybe if maybe.nothing?
  Concurrent::Maybe.from { fproc.(maybe.value) }
end

class TestMaybeFunctor < Minitest::Test

  def setup
    @just_int = Concurrent::Maybe.just(4)
    @nothing = Concurrent::Maybe.nothing
  end

  def test_id
    id = ->(x) { x }
    assert_equal @nothing, fmap(id, @nothing)
    assert_equal @just_int, fmap(id, @just_int)
  end

  def test_composition
    f = ->(x) { x ** 3 }
    g = ->(x) { x - 3 }
    assert_equal @nothing, fmap(f << g, @nothing)
    assert_equal fmap(f, fmap(g, @nothing)), fmap(f << g, @nothing)
    assert_equal Concurrent::Maybe.just(1), fmap(f << g, @just_int)
    assert_equal fmap(f, fmap(g, @just_int)), fmap(f << g, @just_int)

  end
end
