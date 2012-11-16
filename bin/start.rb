#!/usr/bin/env ruby
$: << File.join(File.dirname(__FILE__), "..", "lib")

require 'wolfpack'

app_dir = File.join(File.dirname(__FILE__), "..", "app")
$: << app_dir
Dir[File.join(app_dir, "**/*.rb")].each do |file|
  require file
end

Wolfpack.start(ARGV[0])
