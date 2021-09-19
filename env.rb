require 'net/http'
require "json"
require "time"
require 'openssl'
require "erb"
require "irb"


require "#{File.dirname(__FILE__)}/models/config.rb"

Dir["#{Config.global.root}/models/*"].each do |m|
  require "#{Config.global.root}/models/#{File.basename(m)}"
end
Dir["#{Config.global.root}/controllers/*"].each do |m|
  require "#{Config.global.root}/controllers/#{File.basename(m)}"
end








