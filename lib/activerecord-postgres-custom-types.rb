require 'active_record'
require 'active_record/connection_adapters/postgresql_adapter'

if defined? Rails
	require "activerecord-postgres-custom-types/railties"
else
	ActiveSupport.on_load :active_record do
		require "activerecord-postgres-custom-types/active_record"
	end
end

require "activerecord-postgres-custom-types/abstract_type_class"
require "activerecord-postgres-custom-types/composite_type_parser"