source 'https://support.puzzleflow.com/packages'
# source 'http://rubygems.org'

AR_VERSION = '4.1.0'

gem 'activerecord', "~> #{AR_VERSION}"
gem 'pg-binaries', '1.0.2', require: 'pg_binaries'
gem 'pg', '0.17.0'

group :development do
	gem 'test-unit', '~> 2.1'
	gem 'shoulda', '>= 0'
	gem 'rdoc', '~> 3.12'
	gem 'rake', '~> 10.3'
	gem 'bundler', '~> 1.0'
	gem 'jeweler', '~> 2.0.1' unless RUBY_PLATFORM =~ /mswin/
	gem 'simplecov', '>= 0'
	gem 'combustion', '~> 0.5.2'
	gem 'tzinfo-data' if AR_VERSION > '3.2.0'
end
