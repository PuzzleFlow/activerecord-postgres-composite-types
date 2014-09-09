# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

unless RUBY_PLATFORM =~ /mswin/
	require 'jeweler'
	Jeweler::Tasks.new do |gem|
		# gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
		gem.name = "activerecord-postgres-composite-types"
		gem.homepage = "http://github.com/rafalbigaj/activerecord-postgres-composite-types"
		gem.license = "MIT"
		gem.summary = %Q{ActiveRecord composite types support}
		gem.description = %Q{This gem adds support to the ActiveRecord (3.x and 4.x) for composite types.}
		gem.email = "rafal.bigaj@puzzleflow.com"
		gem.authors = ["Rafal Bigaj"]
		# dependencies defined in Gemfile
	end
	Jeweler::RubygemsDotOrgTasks.new
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

desc "Code coverage detail"
task :simplecov do
  ENV['COVERAGE'] = "true"
  Rake::Task['test'].execute
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "activerecord-postgres-custom-types #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
