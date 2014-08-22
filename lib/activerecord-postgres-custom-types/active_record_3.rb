# ActiveRecord 3.X specific extensions.
module ActiveRecord

	module ConnectionAdapters

		class PostgreSQLAdapter
			# Cast a +value+ to a type that the database understands.
			def type_cast_with_custom_types(value, column)
				case value
					when PostgresAbstractCustomType
						PostgreSQLColumn.custom_type_to_string(value, self)
					when Array, Hash
						if klass = column.custom_type_class
							value = klass.new(value)
							PostgreSQLColumn.custom_type_to_string(value, self)
						else
							type_cast_without_custom_types(value, column)
						end
					else
						type_cast_without_custom_types(value, column)
				end
			end

			alias_method_chain :type_cast, :custom_types
		end

		class PostgreSQLColumn < Column
			# Adds custom type for the column.

			# Casts value (which is a String) to an appropriate instance.
			def type_cast_with_custom_types(value)
				if custom_type_klass = PostgreSQLAdapter.custom_type_classes[type]
					self.class.string_to_custom_type(custom_type_klass, value)
				else
					type_cast_without_custom_types(value)
				end
			end

			alias_method_chain :type_cast, :custom_types

			# quote_and_escape - Rails 4 code

			ARRAY_ESCAPE = "\\" * 2 * 2 # escape the backslash twice for PG arrays

			def self.quote_and_escape(value)
				case value
					when "NULL", Numeric
						value
					else
						value = value.gsub(/\\/, ARRAY_ESCAPE)
						value.gsub!(/"/, "\\\"")
						"\"#{value}\""
				end
			end

			def self.custom_type_to_string(object, adapter)
				quoted_values = object.class.columns.collect do |column|
					value = object.send(column.name)
					if String === value
						if value == "NULL"
							"\"#{value}\""
						else
							quote_and_escape(adapter.type_cast(value, column))
						end
					else
						adapter.type_cast(value, column)
					end
				end
				"(#{quoted_values.join(',')})"
			end

			def type_cast_code_with_custom_types(var_name)
				if custom_type_klass = PostgreSQLAdapter.custom_type_classes[type]
					"#{self.class}.string_to_custom_type(#{custom_type_klass}, #{var_name})"
				else
					type_cast_code_without_custom_types(value)
				end
			end

			alias_method_chain :type_cast_code, :custom_types
		end
	end

	module AttributeMethods
		module CustomTypes
			extend ActiveSupport::Concern

			def type_cast_attribute_for_write(column, value)
				if klass = column.custom_type_class
					# Cast Hash and Array to custom type klass
					if value.is_a?(klass)
						value
					else
						klass.new(value)
					end
				else
					super(column, value)
				end
			end
		end
	end

	Base.send :include, AttributeMethods::CustomTypes
end
