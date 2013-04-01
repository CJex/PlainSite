# coding:utf-8
require 'rake'
require 'rake/testtask'
require 'rdoc'
require 'PlainSite'

task :default => [:list]

desc 'List available tasks'
task :list do
  sh 'rake -T'
end

desc 'Run irb'
task :irb do
  sh 'irb -rubygems -I"lib:test"'
end



Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.pattern = 'test/*.rb'
  test.verbose = true
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "PlainSite v#{PlainSite::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

