
task :default => 
  [ 
   :slides,
  ]

task :test do
  sh "ruby asir.rb"
end


task :slides => 
  [
   'asir.slides',
  ]

ENV['SCARLET'] ||= File.expand_path("../../scarlet/bin/scarlet", __FILE__)
ENV['RITERATE'] ||= File.expand_path("../../riterate/bin/riterate", __FILE__)

file 'asir.slides' => [ 'asir.rb', 'sample_service.rb', 'examples.rb' ] do
  sh "$RITERATE asir.rb sample_service.rb examples.rb"
end

