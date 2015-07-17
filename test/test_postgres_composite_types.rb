require_relative 'helper'

class TestPostgresCompositeTypes < ActiveSupport::TestCase
  class Foo < ActiveRecord::Base
  end

  class MyValue < ActiveRecord::Base
		self.table_name = 'my_table'
  end

  teardown do
	  Foo.delete_all '(comp).f1 NOT IN (0,1)'
  end

  test "cast value properly" do
    foos = Foo.all
    assert_equal 2, foos.size
    assert_equal 0, foos[0].comp.f1
    assert_equal "abc", foos[0].comp.f2
    assert_equal 1, foos[1].comp.f1
    assert_equal "a/b'c\\d e f", foos[1].comp.f2
  end

  test "accept composite type in where clausure" do
    sql = Foo.where(comp: Compfoo.new([123, 'text 1'])).to_sql
    assert_equal %Q(SELECT "foos".* FROM "foos" WHERE "foos"."comp" = '(123,"text 1")'::compfoo), sql.gsub(/ +/, ' ')
  end

  test "create new record with compound object" do
    foo = Foo.create!(comp: Compfoo.new([123, 'text 1']))

    assert_kind_of Compfoo, foo.comp
    assert_equal 123, foo.comp.f1
    assert_equal 'text 1', foo.comp.f2
    assert Foo.where(comp: Compfoo.new([123, 'text 1'])).exists?
  end

  test "create new record with hash" do
    foo = Foo.create!(comp: {f1: 321, f2: 'text 2'})

    assert_kind_of Compfoo, foo.comp
    assert_equal 321, foo.comp.f1
    assert_equal 'text 2', foo.comp.f2
    assert Foo.where(comp: Compfoo.new({f1: 321, f2: 'text 2'})).exists?
  end

  test "create new record with array" do
    foo = Foo.create!(comp: [111, 'text 3'])

    assert_kind_of Compfoo, foo.comp
    assert_equal 111, foo.comp.f1
    assert_equal 'text 3', foo.comp.f2
    assert Foo.where(comp: Compfoo.new({f1: 111, f2: 'text 3'})).exists?
  end

  test 'make object nil' do
    foo = Foo.create!(comp: [333, 'ala ma kota'])
    foo.comp = nil

    assert_nil foo.comp

    Foo.where(comp: Compfoo.new([333, 'ala ma kota'])).delete_all
  end

	test 'accept nil value' do
		mt = MyValue.create!(value: nil)
		assert_nil mt.value

		MyValue.where(value: nil).delete_all
	end
end
