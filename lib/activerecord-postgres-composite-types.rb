require 'active_record'
require 'active_record/connection_adapters/postgresql_adapter'

if defined? Rails
	require "activerecord-postgres-composite-types/railties"
else
	ActiveSupport.on_load :active_record do
		require "activerecord-postgres-composite-types/active_record"
	end
end

require "activerecord-postgres-composite-types/postgres_composite_type"
require "activerecord-postgres-composite-types/composite_type_parser"
