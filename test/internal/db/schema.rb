require "activerecord-postgres-custom-types/activerecord"

class Compfoo < PostgresAbstractCustomType
	consist_of [:f1, nil, 'int4', true],
						 [:f2, nil, 'text', true]
end

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.register_custom_types(compfoo: Compfoo)

ActiveRecord::Schema.define do
	execute "CREATE TYPE compfoo AS (f1 int, f2 text)"

	create_table :foos, :id => false do |t|
		t.compfoo :comp, default: Compfoo.new([0,''])
	end

	execute "INSERT INTO foos VALUES ((0,'abc')), ((1,'a/b''c\\d e f'))"

	connection.send(:reload_type_map)
end
