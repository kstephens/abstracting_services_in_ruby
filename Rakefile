
# YUCK! http://stackoverflow.com/questions/4755900/how-to-make-jruby-1-6-default-to-ruby-1-9
ENV['JRUBY_OPTS'] ||= '--1.9' 

require "bundler/gem_tasks"

gem 'rspec'
require 'rspec/core/rake_task'

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  # Put spec opts in a file named .rspec in root
end

desc "Generate code coverage"
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

######################################################################

desc "Default => :test"
task :default => :test

desc "Run all tests"
task :test => [ :spec, :hack_night ]

desc "Run examples."
task :example do
  ENV["ASIR_EXAMPLE_SILENT"]="1"
  Dir["example/ex[0-9]*.rb"].each do | rb |
    sh %Q{ruby -I example -I lib #{rb}}
  end
  ENV.delete("ASIR_EXAMPLE_SILENT")
end

desc "Run hack_night solutions."
task :hack_night do
  Dir["hack_night/solution/prob-*.rb"].each do | rb |
    sh "ruby -I hack_night/solution #{rb}"
  end
end

desc "Start IRB with ASIR loaded."
task :irb do
  sh "irb -Ilib -rasir"
end

desc "Create slides."
task :slides => 
  [
   'asir.slides/index.html',
  ]

ENV['SCARLET'] ||= File.expand_path("../../scarlet/bin/scarlet", __FILE__)
ENV['RITERATE'] ||= File.expand_path("../../riterate/bin/riterate", __FILE__)

SLIDE_RB = 
  Dir['lib/**/*.rb'] + 
  Dir['example/**/*.rb'] 

file 'asir.slides/index.html' => 
  SLIDE_RB +
  Dir['../riterate/bin/riterate'] +
  [ 'Rakefile' ] + 
  Dir["stylesheets/*.*"] + 
  Dir["asir.riterate.yml"] do
  sh "$RITERATE --slides_basename=asir --ruby_opts='-I lib -I example' #{SLIDE_RB * " "}"
end

desc "Publish slides."
task :publish => [ :slides ] do
  sh "rsync $RSYNC_OPTS -aruzv --delete-excluded --delete --exclude='.git' --exclude='.riterate' ./ kscom:kurtstephens.com/pub/ruby/#{File.basename(File.dirname(__FILE__))}/"
end

desc "Clean garbage."
task :clean do
  sh "rm -rf *.slides* .riterate"
end

