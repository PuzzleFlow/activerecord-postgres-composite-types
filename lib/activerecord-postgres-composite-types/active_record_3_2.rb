# ActiveRecord 3.X specific extensions.
module ActiveRecord

  module ConnectionAdapters

    class PostgreSQLAdapter
	    # Quotes the column value to help prevent {SQL injection attacks}
	    def quote_with_composite_types(value, column = nil)
		    if value.class < PostgresCompositeType
			    "'#{PostgreSQLColumn.composite_type_to_string(value, self).gsub(/'/, "''")}'"
		    else
			    quote_without_composite_types(value, column)
		    end
	    end
	    alias_method_chain :quote, :composite_types

	    # Cast a +value+ to a type that the database understands.
      def type_cast_with_composite_types(value, column)
        case value
          when PostgresCompositeType
            PostgreSQLColumn.composite_type_to_string(value, self)
          when Array, Hash
            if (klass = column.composite_type_class)
              value = klass.new(value)
              PostgreSQLColumn.composite_type_to_string(value, self)
            else
              type_cast_without_composite_types(value, column)
            end
	        else
            type_cast_without_composite_types(value, column)
        end
      end
      alias_method_chain :type_cast, :composite_types

			class << self
				def register_oid_type(klass)
					Arel::Visitors::Visitor.module_eval <<-RUBY, __FILE__, __LINE__
						def visit_#{klass.name.gsub('::', '_')}(o, a=nil)
							o.quoted_value
						end
					RUBY
				end
			end
    end

    class PostgreSQLColumn < Column
      # Adds composite type for the column.

      # Casts value (which is a String) to an appropriate instance.
      def type_cast_with_composite_types(value)
        if (composite_type_klass = PostgreSQLAdapter.composite_type_classes[type])
          self.class.string_to_composite_type(composite_type_klass, value)
        else
          type_cast_without_composite_types(value)
        end
      end
      alias_method_chain :type_cast, :composite_types

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

      def self.composite_type_to_string(object, adapter)
        quoted_values = object.class.columns.collect do |column|
          value = object.send(column.name)
          if String === value
            if value == "NULL"
              "\"#{value}\""
            else
              quote_and_escape(adapter.type_cast(value, column))
            end
          else
	          res = adapter.type_cast(value, column)
	          if value.class < PostgresCompositeType
		          quote_and_escape(res)
	          else
		          res
	          end
          end
        end
        "(#{quoted_values.join(',')})"
      end

      def type_cast_code_with_composite_types(var_name)
        if composite_type_klass = PostgreSQLAdapter.composite_type_classes[type]
          "#{self.class}.string_to_composite_type(#{composite_type_klass}, #{var_name})"
        else
          type_cast_code_without_composite_types(var_name)
        end
      end

      alias_method_chain :type_cast_code, :composite_types
    end
  end

  module AttributeMethods
    module CompositeTypes
      extend ActiveSupport::Concern

      def type_cast_attribute_for_write(column, value)
        if column && !value.nil? && (klass = column.composite_type_class)
          # Cast Hash and Array to composite type klass
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

  Base.send :include, AttributeMethods::CompositeTypes
end
