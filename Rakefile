
task :default => 
  [ 
   :slides,
  ]

task :test do
  sh "ruby asir.rb"
end


task :slides => [ 'asir.slides', 'active_object.slides' ]

ENV['SCARLET'] ||= File.expand_path("../../scarlet/bin/scarlet", __FILE__)
ENV['RITERATE'] ||= File.expand_path("../../riterate/bin/riterate", __FILE__)

file 'asir.slides' => [ 'asir.rb' ] do
  sh "$RITERATE asir.rb"
end

file 'active_object.slides' => [ 'active_object.rb' ] do
  sh "$RITERATE active_object.rb"
end
