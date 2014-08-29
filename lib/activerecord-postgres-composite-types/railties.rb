require 'rails'

# = Postgres Composite Types Railtie
#
# Creates a new railtie to initialize ActiveRecord properly

class PostgresCompositeTypesRailtie < Rails::Railtie

  initializer 'activerecord-postgres-composite-types' do
    ActiveSupport.on_load :active_record do
      require "activerecord-postgres-composite-types/active_record"
    end
  end

end

