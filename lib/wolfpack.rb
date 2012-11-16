src_path = File.expand_path(File.join(File.dirname(__FILE__), "..",  "src"))
$CLASSPATH << src_path
require 'bundler'
Bundler.require(:default)
require 'wolfpack/server'

ZFW_ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))

module Wolfpack
  def self.start(input)
    Wolfpack::Server.new(File.join(ZFW_ROOT, "config", "routes.yml")).run
  end
end
