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
						@custom_type_class.new(value)
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
				def register_oid_type(type, klass)
					OID.register_type type.to_s, OID::CustomType.new(klass)
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
					# adapter.quote(value, column)
				end
				"(#{quoted_values.join(',')})"
			end


		end
	end
end
