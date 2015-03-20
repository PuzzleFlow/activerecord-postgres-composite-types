module ActiveRecord
	module ConnectionAdapters
		class PostgreSQLAdapter
			module OID
				class CompositeType < Type
					def initialize(composite_type_class)
						@composite_type_class = composite_type_class
					end

					# Casts value (which is a String) to an appropriate instance.
					def type_cast(value)
						PostgreSQLColumn.string_to_composite_type(@composite_type_class, value)
						# @composite_type_class.new(value)
					end

					# Casts a Ruby value to something appropriate for writing to the database.
					def type_cast_for_write(value)
						# Cast Hash and Array to composite type klass
						if value.is_a?(@composite_type_class) || value.nil?
							value
						else
							@composite_type_class.new(value)
						end
					end
				end
			end
		end
	end
end