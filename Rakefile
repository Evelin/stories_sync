require 'rubygems'
require 'rake'
require 'rake/testtask'

desc 'Default task: run all tests'
task :default => [:test]

namespace :test do
  task :env do
    ENV["RACK_ENV"] = "test"
  end
end

desc "Run all test"
Rake::TestTask.new :test => ["test:env"] do |t|
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end
