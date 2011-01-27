require File.dirname(__FILE__) + '/provider'
require 'rubygems'
require 'sinatra'

##### Host ... for testing ...
require 'sinatra'

class Dog < OData::EntityType
  include InitializedByAttributes

  key :id

  attr_property :id,   String
  attr_property :name, String

  def self.all_entities
    [
      Dog.new(:id => 1, :name => 'Rover'),
      Dog.new(:id => 2, :name => 'Lander'),
      Dog.new(:id => 3, :name => 'Murdoch'),
      Dog.new(:id => 4, :name => 'Spot'),
      Dog.new(:id => 5, :name => 'Rex')
    ]
  end
end

use OData::Provider::Rack::Middleware, :provider => OData::Provider.new(Dog), :service_root => '/Animals.svc'

get '/' do
  root = '/Animals.svc/'
  %[Hello.  You probably want to check out <a href="#{root}">#{root}</a>]
end
