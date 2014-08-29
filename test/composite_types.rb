
if ActiveRecord::VERSION::MAJOR > 3
	ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID.alias_type 'rgb_color', 'text'
end

class Compfoo < PostgresCompositeType
	register_type :compfoo
end

class MyType < PostgresCompositeType
	register_type :my_type
end

class NestedType < PostgresCompositeType
	register_type :nested_type
end
