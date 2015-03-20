module ActiveRecord
	module ConnectionAdapters
		module PostgreSQL
			module OID
				class CompositeType < OID::Array

					def initialize(composite_type_class)
						@composite_type_class = composite_type_class
						@delimiter = ','
					end

					def type
						@composite_type_class.type
					end

					def type_cast_from_database(value)
						PostgreSQLColumn.string_to_composite_type(@composite_type_class, value)
					end

					def type_cast_from_user(value)
						if value.is_a?(@composite_type_class) || value.nil?
							value
						else
							@composite_type_class.new(value)
						end
					end


					def type_cast_for_database(object)
						return object if object.is_a?(String) # already quoted by AREL visitor
						return "NULL" if object == nil
						quoted_values = object.class.columns.collect do |column|
							value = object.send(column.name)
							if String === value
								quote_and_escape(column.type_cast_for_database(value))
							else
								res = column.type_cast_for_database(value)
								if value.class < PostgresCompositeType
									quote_and_escape(res)
								else
									res
								end
							end
						end
						"(#{quoted_values.join(',')})"
					end

					# Overwrite OID::Array method - regular brackets () instead of {} have to be escaped
					def string_requires_quoting?(string)
						string.empty? ||
								string == "NULL" ||
								string =~ /[\(\)"\\\s]/ ||
								string.include?(delimiter)
					end

				end
			end
		end
	end
end