SCARLET = File.expand_path("~/local/src/scarlet/bin/scarlet")
ENV['SCARLET'] ||= SCARLET


task :default => 
  [ 
   :slides,
  ]

task :test do
  sh "ruby asir.rb"
end


task :slides => [ 'asir.slides', 'active_object.slides' ]

ENV['SCARLET'] ||= File.expand_path("../scarlet/bin/scarlet")

file 'asir.slides' => [ 'asir.rb' ] do
  sh "ruby ./literate_ruby_slides.rb asir.rb"
end

file 'active_object.slides' => [ 'active_object.rb' ] do
  sh "ruby ./literate_ruby_slides.rb active_object.rb"
end
