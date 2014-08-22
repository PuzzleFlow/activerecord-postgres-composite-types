class PostgresAbstractCustomType
	class_attribute :columns

	def self.inherited(subclass)
		super
		subclass.columns = []
	end

	def self.consist_of(*column_definitions)
		column_definitions.each do |name, default, sql_type = nil, null = nil|
			self.columns << postgres_column(name, default, sql_type, null)
			attr_accessor name
		end
	end

	def initialize(value)
		case value
			when String
				load value
			when Array
				set_values value
			when Hash
				set_attributes value
			else
				raise "Unexpected value: #{value.inspect}"
		end
	end

	# Load values from the +value+ which is a db string
	def load(value)
		if value[0] == ?( && value[value.length-1] == ?)
			values = value[1..value.length-2].split(',')
			raise "Invalid number of custom type fields: #{values.size}, expected: #{self.columns.size}" if values.size != self.class.columns.size

			self.class.columns.each.with_index do |column, i|
				cv = column.type_cast(values[i])
				if cv.is_a?(String)
					# unquote
					cv = cv.upcase == 'NULL' ? nil : cv.gsub(/\A"(.*)"\Z/m,'\1').gsub(/\\(.)/, '\1')
				end
				send "#{column.name}=", cv
			end
		else
			raise "Invalid custom type value: #{value.inspect}"
		end
	end

	private

	def self.postgres_column(name, default, sql_type, null)
		if ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.const_defined?(:OID) # Rails 4.X
			oid = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::NAMES[sql_type]
			ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new(name, default, oid, sql_type, null)
		else # Rails 3.X
			ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new(name, default, sql_type, null)
		end
	end

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