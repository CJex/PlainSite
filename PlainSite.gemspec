# encoding: utf-8

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "PlainSite"

Gem::Specification.new do |s|
  s.name       = 'PlainSite'
  s.version    = PlainSite::VERSION
  s.license    = 'MIT'
  s.date       = '2013-08-25'
  s.author     = 'Jex'
  s.email      = 'i@jex.im'
  s.homepage   = 'https://github.com/CJex/PlainSite'
  s.summary    = 'A Truely Hackable Static Site Generator.'
  s.description  = 'PlainSite is a simple but powerful static site generator inspired by Jekyll and Octopress.'

  s.files    = Dir['**/*'].reject { |f|
    (File.directory? f) || (f.end_with? ".gem")
  }

  s.test_files   = s.files.select { |path| path =~ /^test\/.*_test\.rb/ }
  s.require_path = 'lib'
  s.bindir     = 'bin'
  s.executables  = ['plainsite']

  s.required_ruby_version = '>= 1.9.3'

  [
    'pygments.rb', '~> 1.2',
    'kramdown', '~> 1.17',
    'safe_yaml', '~> 1.0',
    'git', '~> 1.5',
    'rake', '~> 12.3',
    'commander', '~> 4.4',
    'listen', '~> 3.1'
  ].each_slice(2) do |a|
    s.add_runtime_dependency *a
  end

end
