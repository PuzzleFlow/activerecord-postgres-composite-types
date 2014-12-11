# ActiveRecord 3.X specific extensions.
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
            if value.is_a?(@composite_type_class)
              value
            else
              @composite_type_class.new(value)
            end
          end
        end
      end

      class << self
        def register_oid_type(klass)
          OID.register_type klass.type.to_s, OID::CompositeType.new(klass)
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
