desc "Prepare bundler"
task :prebundle do
   sh 'gem install bundler --version "~> 1.3.1" --no-rdoc --no-ri'
end

desc "Requires"
task :req do
   $: << File.expand_path( '../lib', __FILE__ )
   require 'bundler/gem_helper'

   Bundler::GemHelper.install_tasks
end

desc "Prepare bundle environment"
task :pre do
   sh 'bundle install'
end

desc "Generate gem"
task :gem do
   sh 'gem build znamen.gemspec'
   sh "gem install znamen-#{Znamen::VERSION}.gem"
end

desc "Distilled clean"
task :distclean do
   sh 'git clean -fd'
   sh 'rm -rf $(find -iname "*~")'
end

task :book do
   sh './bin/book.rb'
end


task(:default).clear
task :default => :pre
task :release => [ :req ]
task :gem => [ :req ]
task :build => [ :prebundle, :pre, :gem ]
