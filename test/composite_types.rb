
if ActiveRecord::VERSION::MAJOR > 3
	ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID.alias_type 'rgb_color', 'text'
end

class Compfoo < PostgresAbstractCustomType
	register_type :compfoo
end

class MyType < PostgresAbstractCustomType
	register_type :my_type
end

class NestedType < PostgresAbstractCustomType
	register_type :nested_type
end
