require 'rails'

# = Postgres Custom Types Railtie
#
# Creates a new railtie to initialize ActiveRecord properly

class PostgresCustomTypesRailtie < Rails::Railtie

  initializer 'activerecord-postgres-custom-types' do
    ActiveSupport.on_load :active_record do
      require "activerecord-postgres-custom-types/activerecord"
    end
  end

end

