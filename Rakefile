SCARLET = File.expand_path("~/local/src/scarlet/bin/scarlet")
ENV['SCARLET'] ||= SCARLET


task :default => [ 
                  :slides,
                  :test, 
                 ]

task :test do
  sh "ruby asir.rb"
end

task :slides do
  ENV['SCARLET'] ||= File.expand_path("../scarlet/bin/scarlet")
  sh "ruby ./literate_ruby_slides.rb asir.rb"
end
