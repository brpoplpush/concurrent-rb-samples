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
      :*.to_proc.(@just_a, @just_b)
    end
    @just_str = Concurrent::Maybe.just("klingon")
    @nothing = Concurrent::Maybe.nothing
    @nothing_result = Concurrent::Maybe.from do
      :+.to_proc.(@just_str, @nothing)
    end
  end

  def test_just_a
    assert_equal true, @just_a.just?
    assert_equal 2, @just_a.value
    assert_equal false, @just_a.nothing?
    # No error class
    assert_equal Object, @just_a.reason.class
  end
end
