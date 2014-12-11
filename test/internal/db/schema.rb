require "activerecord-postgres-composite-types/active_record"

ActiveRecord::Schema.define do
  execute "CREATE TYPE compfoo AS (f1 int, f2 text)"
  execute "CREATE TYPE my_type AS (name varchar, number int, date timestamp)"
  execute "CREATE DOMAIN rgb_color AS TEXT CHECK(VALUE IN ('red', 'green', 'blue'))"
  execute "CREATE TYPE nested_type AS (comp compfoo, color rgb_color)"
  execute "CREATE TYPE nested_nested_type AS (nested nested_type, color rgb_color)"

  create_table :foos, :id => false do |t|
    t.column :comp, :compfoo, default: "(0,\"\")"
  end

  create_table :bars, :id => false do |t|
    t.column :nested, :nested_type
  end

  create_table :bar2s, :id => false do |t|
    t.column :nested, :nested_nested_type
  end

  execute "INSERT INTO foos VALUES ((0,'abc')), ((1,'a/b''c\\d e f'))"
  execute "INSERT INTO bars VALUES (((0,'abc'),'red')), (((1,'cba'),'blue'))"
end
