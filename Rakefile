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
  require 'erb'
  slides_textile = 'slides.textile'
  sh "ruby ./literate_ruby_slides.rb asir.rb > #{slides_textile}.erb"
  erb = ERB.new(File.read(erb_file = "#{slides_textile}.erb"))
  erb.filename = erb_file
  textile = erb.result(binding)
  textile.gsub!(/"":relative:([^\s]+)/){|x| %Q{<a href="#{$1}">#{$1}</a>}}
  textile.gsub!(/"":(https?:[^\s]+)/){|x| %Q{"#{$1}":#{$1}}}
  File.open(slides_textile, "w+") { | out | out.puts textile }
  $stderr.puts "Created #{slides_textile}"
  scarlet = (ENV['SCARLET'] ||= File.expand_path("../scarlet/bin/scarlet"))
  # system "#{scarlet} -g slides -f html slides.textile"
  system "set -x; mkdir -p slides/stylesheets slides/javascripts slides/image"
  system "set -x; #{scarlet} -f html slides.textile > slides/index.html"
  system "set -x; cp -p image/*.* slides/image/" if File.directory?("image")
  system "set -x; cp -p stylesheets/*.* slides/stylesheets/"
  system "set -x; cp -p javascripts/*.* slides/javascripts/"
end
