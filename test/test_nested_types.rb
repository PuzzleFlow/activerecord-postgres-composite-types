require_relative 'helper'

class TestNestedTypes < Test::Unit::TestCase
	class Bar < ActiveRecord::Base
	end

  setup do
    Bar.delete_all
    Bar.create(nested: {comp: Compfoo.new([0, 'abc']), color: 'red'})
    Bar.create(nested: {comp: Compfoo.new([1, 'cba']), color: 'blue'})
  end

	should "cast value properly" do
		bars = Bar.order('(nested).comp.f1').all
		assert_equal 2, bars.size
		assert_kind_of NestedType, bars[0].nested
		assert_equal Compfoo.new([0,'abc']), bars[0].nested.comp
		assert_equal 'red', bars[0].nested.color
		assert_kind_of NestedType, bars[1].nested
		assert_equal Compfoo.new([1,'cba']), bars[1].nested.comp
		assert_equal 'blue', bars[1].nested.color
	end

  should "insert with nested type" do
    bar = Bar.new(nested: {comp: Compfoo.new([2, 'bac']), color: 'red'})
    bar.save
    assert !bar.new_record?
  end
end
