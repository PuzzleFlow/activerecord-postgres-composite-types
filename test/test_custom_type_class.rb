require_relative 'helper'

class TestCustomTypeClass < Test::Unit::TestCase
	class MyTypeClass < PostgresAbstractCustomType
		consist_of [:number, nil, 'int4', true],
							 [:text, nil, 'text', true]
	end

	should "define accessors" do
		assert MyTypeClass.method_defined?(:number)
		assert MyTypeClass.method_defined?(:number=)
		assert MyTypeClass.method_defined?(:text)
		assert MyTypeClass.method_defined?(:text=)
	end

	should "initialize with string" do
		value = MyTypeClass.new("(5,text)")
		assert_equal 5, value.number
		assert_equal 'text', value.text
	end

	should "accept escaped string" do
		value = MyTypeClass.new('(125,"text\'s")')
		assert_equal 125, value.number
		assert_equal "text's", value.text
	end

	should "initialize with hash" do
		value = MyTypeClass.new(number: 1, text: 'abc')
		assert_equal 1, value.number
		assert_equal 'abc', value.text
	end

	should "cast to qouted string" do
		value = MyTypeClass.new(number: 1, text: '"\'a\'bc[]*/\"')
		assert_equal "(1,'\"''a''bc[]*/\\\"')", value.quote(connection)
	end
end
