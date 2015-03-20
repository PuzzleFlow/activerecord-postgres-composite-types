require 'simplecov'

module SimpleCov::Configuration
  def clean_filters
    @filters = []
  end
end

SimpleCov.configure do
  clean_filters
  load_profile 'test_frameworks'
end

ENV["COVERAGE"] && SimpleCov.start do
  add_filter "/.rvm/"
end
require 'rubygems'
require 'bundler'
begin
  Bundler.require(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'activerecord-postgres-composite-types'

ActiveSupport.on_load :active_record do
  require_relative 'composite_types'
end

Combustion.path = 'test/internal'
Combustion.initialize! :active_record

ActiveRecord::Base.default_timezone = :utc

class Test::Unit::TestCase
  def connection
    ActiveRecord::Base.connection
  end
end
