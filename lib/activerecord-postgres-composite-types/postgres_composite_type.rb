class PostgresCompositeType
	include Comparable

	class << self
		# TODO: doc
		attr_reader :type
		# TODO: doc
		attr_reader :columns

		def register_type(type)
			@type = type.to_sym
			ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.register_composite_type_class(self)
		end

		def use_connection_class(active_record_class)
			@connection_class = active_record_class
		end

		def connection
			(@connection_class || ActiveRecord::Base).connection
		end

		def connected?
			(@connection_class || ActiveRecord::Base).connected?
		end

		def initialize_column_definition
			unless @columns
				@columns = self.connection.columns(type)
				attr_accessor *@columns.map(&:name)
			end
		end
	end

	def initialize(value)
		self.class.initialize_column_definition

		case value
			when String
				ActiveRecord::ConnectionAdapters::PostgreSQLColumn.string_to_composite_type(self.class, value)
			when Array
				set_values value
			when Hash
				set_attributes value
			else
				raise "Unexpected value: #{value.inspect}"
		end
	end

	def <=>(another)
		return nil if (self.class <=> another.class) == nil
		self.class.columns.each do |column|
			v1 = self.send(column.name)
			v2 = another.send(column.name)
			return v1 <=> v2 unless v1 == v2
		end
		0
	end

	private

	def set_attributes(values)
		values.each do |name, value|
			send "#{name}=", value
		end
	end

	def set_values(values)
		raise "Invalid values count: #{values.size}, expected: #{self.class.columns.size}" if values.size != self.class.columns.size
		self.class.columns.each.with_index do |column, i|
			send "#{column.name}=", values[i]
		end
	end

end