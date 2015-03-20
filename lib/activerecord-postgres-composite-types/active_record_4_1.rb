# ActiveRecord 4.0, 4.1 specific extensions.

require_relative 'oid/composite_type'

module ActiveRecord

  module ConnectionAdapters

    class PostgreSQLAdapter
      class << self
        def register_oid_type(klass)
          OID.register_type klass.type.to_s, OID::CompositeType.new(klass)
          # Dirty. Only this type should be added to type map
          klass.connection.send(:reload_type_map) if klass.connected?
        end
      end

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
      def type_cast_with_composite_types(value, column, array_member = false)
        case value
          when PostgresCompositeType
            PostgreSQLColumn.composite_type_to_string(value, self)
          when Array, Hash
            if klass = column.composite_type_class
              value = klass.new(value)
              PostgreSQLColumn.composite_type_to_string(value, self)
            else
              type_cast_without_composite_types(value, column, array_member)
            end
          else
            type_cast_without_composite_types(value, column, array_member)
        end
      end

      alias_method_chain :type_cast, :composite_types
    end

    class PostgreSQLColumn < Column
      # Casts value (which is a String) to an appropriate instance.
      def type_cast_with_composite_types(value)
        if composite_type_klass = PostgreSQLAdapter.composite_type_classes[type]
          self.class.string_to_composite_type(composite_type_klass, value)
        else
          type_cast_without_composite_types(value)
        end
      end

      alias_method_chain :type_cast, :composite_types

      def self.composite_type_to_string(object, adapter)
        quoted_values = object.class.columns.collect do |column|
          value = object.send(column.name)
          if String === value
            if value == "NULL"
              "\"#{value}\""
            else
              quote_and_escape(adapter.type_cast(value, column, true))
            end
          else
            res = adapter.type_cast(value, column, true)
            if value.class < PostgresCompositeType
              quote_and_escape(res)
            else
              res
            end
          end
        end
        "(#{quoted_values.join(',')})"
      end


    end
  end
end
