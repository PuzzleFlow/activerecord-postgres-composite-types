require_relative 'helper'

class TestNestedTypes < Test::Unit::TestCase
	class Bar < ActiveRecord::Base

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
end