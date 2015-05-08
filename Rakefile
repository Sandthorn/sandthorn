#!/usr/bin/env rake
require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

task :benchmark do
  sh "rspec --tag benchmark"
end

task :console do
  require "ap"
  require "pry"
  require "pry/completion"
  require "bundler"
  require "sandthorn"
  ARGV.clear
  Pry.start
end
