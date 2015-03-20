# ActiveRecord 4.2 specific extensions.

require_relative 'oid/composite_type'

module ActiveRecord

	module ConnectionAdapters

    class PostgreSQLAdapter

	    class << self
				mattr_accessor :ordered_composite_type_classes
				self.ordered_composite_type_classes = []

        def register_oid_type(klass)
	        self.ordered_composite_type_classes << klass
          # Dirty. Only this type should be added to type map
	        klass.connection.send(:reload_type_map) if klass.connected?
        end
      end

      # Rails 4.2
      def initialize_type_map_with_composite_types(m)
	      initialize_type_map_without_composite_types(m)
	      self.class.ordered_composite_type_classes.each do |klass|
		      m.register_type klass.type.to_s, OID::CompositeType.new(klass)
	      end
      end
      alias_method_chain :initialize_type_map, :composite_types
    end

    class PostgreSQLColumn < Column
      def self.composite_type_to_string(object, adapter)
				PostgreSQL::OID::CompositeType.new(object.class).type_cast_for_database(object)
      end
    end
  end
end
