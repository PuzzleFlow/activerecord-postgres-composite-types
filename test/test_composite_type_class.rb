require_relative 'helper'

class TestCompositeTypeClass < Test::Unit::TestCase

	PostgreSQLColumn = ActiveRecord::ConnectionAdapters::PostgreSQLColumn

  should "define accessors" do
    assert MyType.method_defined?(:name)
    assert MyType.method_defined?(:name=)
    assert MyType.method_defined?(:number)
    assert MyType.method_defined?(:number=)
    assert MyType.method_defined?(:date)
    assert MyType.method_defined?(:date=)
  end

  should "be created by adapter from string" do
    value = PostgreSQLColumn.string_to_composite_type(MyType, "(text,5,2014-08-27 00:00:00)")
    assert_equal 'text', value.name
    assert_equal 5, value.number
    assert_equal Time.parse('2014-08-27 00:00:00 UTC'), value.date
  end

  should "accept escaped string" do
    value = PostgreSQLColumn.string_to_composite_type(MyType, '("text\'s",125,"2014-08-27 10:00:00")')
    assert_equal "text's", value.name
    assert_equal 125, value.number
    assert_equal Time.parse('2014-08-27 10:00:00 UTC'), value.date
  end

  should "initialize with hash" do
    value = MyType.new(number: 1, name: 'abc', date: Time.parse('2014-08-27 12:00:00 UTC'))
    assert_equal 'abc', value.name
    assert_equal 1, value.number
    assert_equal Time.parse('2014-08-27 12:00:00 UTC'), value.date
  end

  should "cast to qouted string" do
    value = MyType.new(number: 1, name: '"\'a\'bc[]*/\"', date: Time.parse('2014-08-27 12:00:00 UTC'))
    assert_equal %Q{'("\\\"''a''bc[]*/\\\\\\\"",1,2014-08-27 12:00:00.000000)'}, connection.quote(value)
  end

  should "parse string and return array" do
    result = PostgreSQLColumn::CompositeTypeParser.parse_data("(text,5,2014-08-27 00:00:00)")
    assert_equal ["text", "5", "2014-08-27 00:00:00"], result
  end

  should "parse string and return array 2" do
    result = PostgreSQLColumn::CompositeTypeParser.parse_data('(text,5,"(titi,tata)",2014-08-27 00:00:00)')
    assert_equal ["text", "5", '(titi,tata)', "2014-08-27 00:00:00"], result
  end

  should "parse string and return array 3" do
    result = PostgreSQLColumn::CompositeTypeParser.parse_data('(text,5,"(titi,tata,""(tutu""""tata,tete)"")",2014-08-27 00:00:00)')
    assert_equal ["text", "5", '(titi,tata,"(tutu""tata,tete)")', "2014-08-27 00:00:00"], result
  end

end
