# Extends AR to add custom types functionality.
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
							@custom_type_class.new(value) unless value.is_a?(@custom_type_class)
						end
					end
				end
			end

			# Quotes the column value to help prevent {SQL injection attacks}
			def quote_with_custom_types(value, column = nil)
				if value.class < PostgresAbstractCustomType
					"'#{PostgreSQLColumn.custom_type_to_string(value, self).gsub(/'/, "''")}'"
				else
					quote_without_custom_types(value, column)
				end
			end

			alias_method_chain :quote, :custom_types

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

			class << self
				def register_custom_types(custom_types)
					custom_types.each do |type, klass|
						register_custom_type type, klass
					end
				end

				def register_custom_type(type, klass)
					self.custom_type_classes[type.to_sym] = klass
					TableDefinition.register_custom_type type
					Table.register_custom_type type
					OID.register_type type.to_s, OID::CustomType.new(klass)
					register_arel_visitor type, klass
				end

				def register_arel_visitor(type, klass)
					Arel::Visitors::ToSql.class_eval <<-RUBY
						def visit_#{klass}(o, a)
							@connection.quote(o) + '::#{type}'
						end
					RUBY
				end

				# removes custom types definition (for testing)
				def unregister_custom_types(*custom_types)
					custom_types.each { |type| unregister_custom_type type }
				end

				# removes custom type definition (for testing)
				def unregister_custom_type(type)
					self.custom_type_classes.delete(type.to_sym)
					TableDefinition.unregister_custom_type type
					Table.unregister_custom_type type
				end

				def custom_type_classes
					@custom_type_classes ||= {}
				end
			end
		end

		class PostgreSQLColumn < Column
			# Adds custom type for the column.

			def custom_type_class
				PostgreSQLAdapter.custom_type_classes[type]
			end

			def klass_with_custom_types
				custom_type_klass = PostgreSQLAdapter.custom_type_classes[type]
				custom_type_klass || klass_without_custom_types
			end

			alias_method_chain :klass, :custom_types

			# Casts value (which is a String) to an appropriate instance.
			def type_cast_with_custom_types(value)
				if custom_type_klass = PostgreSQLAdapter.custom_type_classes[type]
					self.class.string_to_custom_type(custom_type_klass, value)
				else
					type_cast_without_custom_types(value)
				end
			end

			alias_method_chain :type_cast, :custom_types

			def type_cast_for_write_with_custom_type(value)
				if @oid_type.is_a?(CustomType)
				else

				end
			end

			# ??
			# alias_method_chain :type_cast, :custom_types

			def self.string_to_custom_type(klass, string)
				return string unless String === string
				if string.present?
					klass.new(string)
				end
			end

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


			def type_cast_code_with_custom_types(var_name)
				if custom_type_klass = PostgreSQLAdapter.custom_type_classes[type]
					"#{self.class}.string_to_custom_type(#{custom_type_klass}, #{var_name})"
				else
					type_cast_code_without_custom_types(value)
				end
			end

			# alias_method_chain :type_cast_code, :custom_types

			private

			def simplified_type_with_custom_types(field_type)
				type = field_type.to_sym
				if PostgreSQLAdapter.custom_type_classes.has_key?(type)
					type
				else
					simplified_type_without_custom_types(field_type)
				end
			end

			alias_method_chain :simplified_type, :custom_types
		end

		class << TableDefinition
			# Adds custom type for migrations. So you can add columns to a table like:
			#   create_table :people do |t|
			#     ...
			#     t.custom_type :custom_value
			#     ...
			#   end
			def register_custom_type(custom_type)
				class_eval <<-RUBY
					def #{custom_type}(*args)
						options = args.extract_options!
						column_names = args
						column_names.each { |name| column(name, '#{custom_type}', options) }
					end
				RUBY
			end

			# Removes custom types from migrations (for testing)
			def unregister_custom_type(custom_type)
				remove_method custom_type
			end
		end

		class << Table

			# Adds custom type for migrations. So you can add columns to a table like:
			#   change_table :people do |t|
			#     ...
			#     t.custom_type :custom_value
			#     ...
			#   end
			def register_custom_type(custom_type)
				class_eval <<-RUBY
					def #{custom_type}(*args)
						options = args.extract_options!
						column_names = args
						column_names.each { |name| column(name, '#{custom_type}', options) }
					end
				RUBY
			end

			# Removes custom types from migrations (for testing)
			def unregister_custom_type(custom_type)
				remove_method custom_type
			end
		end
	end
end
