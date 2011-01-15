require 'rubygems'
require 'bundler/setup'
Bundler.require :test

module RackApp
  def app
    lambda {|env| [200, {}, ["Hello World"]]}
  end
end

RSpec.configure do |config|
  config.include RackApp
  config.include Rack::Test::Methods
end
