require 'activerecord-postgres-composite-types/active_record'

class PostgresCompositeType
  include Comparable

  class << self
    # The PostgreSQL type name as symbol
    attr_reader :type
    # Column definition read from db schema
    attr_reader :columns

    # Link PostgreSQL type given by the name with this class.
    # Usage:
    #
    # class ComplexType < PostgresCompositeType
    #   register_type :complex
    # end
    #
    # @param [Symbol] :type the PostgreSQL type name
    def register_type(type)
      @type = type.to_sym
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.register_composite_type_class(self)
    end

    # Be default the ActiveRecord::Base connection is used when reading type definition.
    # If you want to use connection linked with another class use this method.
    # Usage
    #
    # class ComplexType < PostgresCompositeType
    #   register_type :complex
    #   use_connection_class MyRecordConnectedToDifferentDB
    # end
    #
    # @param [Class] :active_record_class the ActiveRecord model class
    def use_connection_class(active_record_class)
      @connection_class = active_record_class
    end

    # :nodoc:
    def connection
      (@connection_class || ActiveRecord::Base).connection
    end

    # :nodoc:
    def connected?
      (@connection_class || ActiveRecord::Base).connected?
    end

    # :nodoc:
    def initialize_column_definition
      unless @columns
        @columns = self.connection.columns(type)
        attr_reader *@columns.map(&:name)
        @columns.each do |column|
	        define_method("#{column.name}=") do |value|
		        instance_variable_set "@#{column.name}", type_cast_field_from_user(column, value)
	        end
        end
      end
    end
  end

  def initialize(value)
    self.class.initialize_column_definition
    case value
      when String
        ActiveRecord::ConnectionAdapters::PostgreSQLColumn.string_to_composite_type(self.class, value)
      when Array
        set_values value
      when Hash
        set_attributes value
      else
        raise "Unexpected value: #{value.inspect}"
    end
  end

  def <=>(another)
    return nil if (self.class <=> another.class) == nil
    self.class.columns.each do |column|
      v1 = self.send(column.name)
      v2 = another.send(column.name)
      return v1 <=> v2 unless v1 == v2
    end
    0
  end

  # Used for AREL eq node
  def quoted_value
	  "'" + ActiveRecord::ConnectionAdapters::PostgreSQLColumn::composite_type_to_string(self, self.class.connection) + "'::#{self.class.type}"
  end

  private

	if ActiveRecord::ConnectionAdapters::PostgreSQLColumn.method_defined?(:type_cast_from_user) # v4.2 and later
	  def type_cast_field_from_user(column, value)
		  column.type_cast_from_user(value)
	  end
	elsif ActiveRecord::ConnectionAdapters::PostgreSQLColumn.method_defined?(:type_cast_for_write) # v4.0 and v4.1
		def type_cast_field_from_user(column, value)
			column.type_cast_for_write(value)
		end
	else # v3.X
		def type_cast_field_from_user(column, value)
			klass = column.composite_type_class
			if klass
				case value
					when Hash, Array
						klass.new(value)
					when String
						ActiveRecord::ConnectionAdapters::PostgreSQLColumn.string_to_composite_type(klass, value)
					else
						value
				end
			else
				value
			end
		end
	end

  def set_attributes(values)
    values.each do |name, value|
      #if Hash === value || Array === value
      #  klass = self.class.columns.find(name).first.try(:composite_type_class)
      #  value = klass.new(value) if klass
      #end
      send "#{name}=", value
    end
  end

  def set_values(values)
    raise "Invalid values count: #{values.size}, expected: #{self.class.columns.size}" if values.size != self.class.columns.size
    self.class.columns.each.with_index do |column, i|
      #if Hash === values[i] || Array === values[i]
      #  klass = column.composite_type_class
      #  values[i] = klass.new(values[i]) if klass
      #end
      send "#{column.name}=", values[i]
    end
  end

  ActiveRecord::PredicateBuilder.register_handler(PostgresCompositeType, ->(attribute, value) {
	  quoted = Arel::Nodes::SqlLiteral.new(value.quoted_value)
	  Arel::Nodes::Equality.new(attribute, quoted)
  }) if ActiveRecord::PredicateBuilder.respond_to?(:register_handler) # v.4.X
end
