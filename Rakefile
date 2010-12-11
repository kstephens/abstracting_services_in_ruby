
begin
  require 'rubygems'
  gem 'jeweler'
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "asir"
    #s.executables = ""
    s.summary = "Abstracting Services in Ruby"
    s.email = "ks.ruby@kurtstephens.com"
    s.homepage = "http://github.com/kstephens/abstracting_services_in_ruby"
    s.description = s.summary
    s.authors = ["Kurt Stephens"]
    s.files = FileList["[A-Z]*", "{bin,lib,test,spec,doc,example,hack_night}/**/*" ]
    #s.add_dependency 'schacon-git'
  end
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install jeweler -s http://gems.github.com"
end

require 'rake'
require 'spec/rake/spectask'

desc "Run all tests with RCov"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_opts = [ '-b' ]
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
  t.rcov_opts = [
                 # '--exclude', 'test', 
                 '--exclude', '/var/lib',
                ]
end

######################################################################

task :default => :test

task :test => [ :spec, :hack_night ]

task :example do
  ENV["ASIR_EXAMPLE_SILENT"]="1"
  Dir["example/ex[0-9]*.rb"].each do | rb |
    sh %Q{ruby -I example -I lib #{rb}}
  end
  ENV.delete("ASIR_EXAMPLE_SILENT")
end

task :hack_night do
  Dir["hack_night/solution/prob-*.rb"].each do | rb |
    sh "ruby -I hack_night/solution #{rb}"
  end
end


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

task :publish => [ :slides ] do
  sh "rsync $RSYNC_OPTS -aruzv --delete-excluded --delete --exclude='.git' --exclude='.riterate' ./ kscom:kurtstephens.com/pub/ruby/#{File.basename(File.dirname(__FILE__))}/"
end

task :clean do
  sh "rm -rf *.slides* .riterate"
end

=begin
file 'asir-sequence.svg' => [ 'asir-sequence.pic', 'sequence.pic' ] do
  sh "pic2plot -Tsvg --font-name HersheySans-Bold --font-size 0.01 tmp.pic > tmp.svg"
  sh "open tmp.svg"
end
=end

