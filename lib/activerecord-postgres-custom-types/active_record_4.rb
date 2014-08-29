# ActiveRecord 3.X specific extensions.
module ActiveRecord

	module ConnectionAdapters

		class PostgreSQLAdapter
			module OID
				class CustomType < Type
					def initialize(custom_type_class)
						@custom_type_class = custom_type_class
					end

					# Casts value (which is a String) to an appropriate instance.
					def type_cast(value)
						PostgreSQLColumn.string_to_custom_type(@custom_type_class, value)
						# @custom_type_class.new(value)
					end

					# Casts a Ruby value to something appropriate for writing to the database.
					def type_cast_for_write(value)
						# Cast Hash and Array to custom type klass
						if value.is_a?(@custom_type_class)
							value
						else
							@custom_type_class.new(value)
						end
					end
				end
			end

			class << self
				def register_oid_type(klass)
					OID.register_type klass.type.to_s, OID::CustomType.new(klass)
					# Dirty. Only this type should be added to type map
					klass.connection.send(:reload_type_map) if klass.connected?
				end
			end

			def add_composite_type_to_map(type)
				oid_type = OID::NAMES[type.to_s]
				raise "OID type: '#{type}' not registered" unless oid_type

				result = execute("SELECT oid, typname, typelem, typdelim, typinput FROM pg_type WHERE typname = '#{type}'", 'SCHEMA')
				raise "Composite type: '#{type}' not defined in PostgreSQL database" if result.empty?
				row = result[0]

				unless type_map.key? row['typelem'].to_i
					type_map[row['oid'].to_i] = vector
				end
			end

			# Cast a +value+ to a type that the database understands.
			def type_cast_with_custom_types(value, column, array_member = false)
				case value
					when PostgresAbstractCustomType
						PostgreSQLColumn.custom_type_to_string(value, self)
					when Array, Hash
						if klass = column.custom_type_class
							value = klass.new(value)
							PostgreSQLColumn.custom_type_to_string(value, self)
						else
							type_cast_without_custom_types(value, column, array_member)
						end
					else
						type_cast_without_custom_types(value, column, array_member)
				end
			end

			alias_method_chain :type_cast, :custom_types
		end

		class PostgreSQLColumn < Column
			# Casts value (which is a String) to an appropriate instance.
			def type_cast_with_custom_types(value)
				if custom_type_klass = PostgreSQLAdapter.custom_type_classes[type]
					self.class.string_to_custom_type(custom_type_klass, value)
				else
					type_cast_without_custom_types(value)
				end
			end

			alias_method_chain :type_cast, :custom_types

			def self.custom_type_to_string(object, adapter)
				quoted_values = object.class.columns.collect do |column|
					value = object.send(column.name)
					if String === value
						if value == "NULL"
							"\"#{value}\""
						else
							quote_and_escape(adapter.type_cast(value, column, true))
						end
					else
						adapter.type_cast(value, column, true)
					end
				end
				"(#{quoted_values.join(',')})"
			end


		end
	end
end
