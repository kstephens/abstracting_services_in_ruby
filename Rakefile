
task :default => 
  [ 
   :slides,
  ]

task :test do
  Dir["example/ex*.rb"].each do | rb |
    sh "ruby -I example -I lib #{rb}"
  end
end


task :slides => 
  [
   'asir.slides/index.html',
  ]

ENV['SCARLET'] ||= File.expand_path("../../scarlet/bin/scarlet", __FILE__)
ENV['RITERATE'] ||= File.expand_path("../../riterate/bin/riterate", __FILE__)

file 'asir.slides/index.html' => Dir['lib/*.rb'] + Dir['example/*.rb'] + [ 'Rakefile' ] + Dir["stylesheets/*.*"] do
  sh "$RITERATE lib/*.rb example/sample_service.rb example/ex*.rb"
end

task :publish => [ :slides ] do
  sh "rsync $RSYNC_OPTS -aruzv --delete-excluded --exclude='.git' --exclude='.riterate' ./ kscom:kurtstephens.com/pub/#{File.basename(File.dirname(__FILE__))}/"
end

task :clean do
  sh "rm -rf *.slides* .riterate"
end

file 'tmp.svg' => [ 'tmp.pic', 'sequence.pic' ] do
  sh "pic2plot -Tsvg --font-name HersheySans-Bold --font-size 0.01 tmp.pic > tmp.svg"
  sh "open tmp.svg"
end

