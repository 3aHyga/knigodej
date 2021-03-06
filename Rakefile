#!/usr/bin/env rake

desc "Prepare bundler"
task :bundleup do
  sh 'gem install bundler --version "~> 1.3" --no-ri --no-rdoc'
end

desc "Requires"
task :req do
   $: << File.expand_path( '../lib', __FILE__ )
   begin
      require 'bundler/gem_helper'
   rescue LoadError
      Rake::Task[ 'bundleup' ].invoke
   end

   Bundler::GemHelper.install_tasks
end

desc "Prepare bundle environment"
task :up do
   sh 'bundle install'
   begin
      require 'bundler/gem_helper'
   rescue LoadError
      Rake::Task[ 'bundleup' ].invoke
   end
end

desc "Test with cucumber"
task :test do
  sh 'if [ -d features ]; then tests=$(ls features/*.feature) ; cucumber $tests; fi'
end

desc "Distilled clean"
task :distclean do
   sh 'git clean -fd'
   sh 'cat .gitignore | while read mask; do rm -rf $(find -iname "$mask"); done'
end

desc "Generate gem"
namespace :gem do
  task :build => [ :req ] do
    sh 'gem build knigodej.gemspec'
  end

  task :install do
    require File.expand_path( '../lib/knigodej/version', __FILE__ )
    sh "gem install knigodej-#{Knigodej::VERSION}.gem"
  end

  task :publish => [ :req ] do
    require File.expand_path( '../lib/knigodej/version', __FILE__ )
    sh "gem push knigodej-#{Knigodej::VERSION}.gem"
    sh "git tag v#{Knigodej::VERSION}"
    sh "git push"
    sh "git push --tag"
  end

  task :make => [ :build, :install, :publish ]
  task :default => :make
end

task(:default).clear
task :default => :test
task :all => [ :bundleup, :up, :test, :'gem:make', :distclean ]
task :build => [ :bundleup, :up, :test, :'gem:build', :'gem:install', :distclean ]

