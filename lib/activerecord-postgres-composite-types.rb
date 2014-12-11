require 'active_record'

if defined? Rails
  require "activerecord-postgres-composite-types/railtie"
else
  ActiveSupport.on_load :active_record do
    require "activerecord-postgres-composite-types/active_record"
    require 'postgres_composite_type'
  end
end
