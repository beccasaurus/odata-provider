#require 'spec_helper'
require File.dirname(__FILE__) + '/../provider'

class Dog < OData::EntityType
  include InitializedByAttributes

  key :id

  attr_property :id,   String
  attr_property :name, String

  #executor OData::RubyQueryExecutor.new { Dog.all_dogs }
  #executor(:ruby){ Dog.all_dogs } # using shorthand for registered executors
  executor :ruby # using conventions

  # assumes *1* key for now ...
  def self.get key
    $dogs.detect {|dog| dog.send(keys.first.name).to_s == key.to_s }
  end

  # our little repository of dogs, for testing
  class << self
    attr_accessor :all_dogs
  end
  @all_dogs ||= []

  # conventional method for the RubyQueryExecutor
  def self.all_entities
    all_dogs
  end
end

describe OData::Provider, '#execute' do

  it 'raises exception is #entity_types does not include the type'

end

describe OData::Provider, '#make_query' do

  before do
    @provider = OData::Provider.new Dog
  end

  it '/Dogs' do
    query = @provider.build_query '/Dogs'
    query.entity_type.should == Dog
    query.options.should be_empty
  end

  it '/Dogs(1)' do
    query = @provider.build_query '/Dogs(1)'
    query.entity_type.should == Dog
    query.options.length.should == 1
    query.options.first.should be_a(OData::QueryOption)
    query.options.first.should be_a(OData::KeyQueryOption)
    query.options.first.value.should == '1'
  end

  it '/Dogs?$top=2' do
    query = @provider.build_query '/Dogs?$top=2'
    query.entity_type.should == Dog
    query.options.length.should == 1
    query.options.first.should be_a(OData::QueryOption)
    query.options.first.should be_a(OData::TopQueryOption)
    query.options.first.value.should == '2'
  end

  it '/Dogs?$top=2$skip=5' do
    query = @provider.build_query '/Dogs?$top=2&$skip=5'
    query.entity_type.should == Dog
    query.options.length.should == 2
    top_option = query.options.detect  {|o| o.is_a? OData::TopQueryOption }
    top_option.value.should == '2'
    skip_option = query.options.detect {|o| o.is_a? OData::SkipQueryOption }
    skip_option.value.should == '5'
  end

end

describe OData::Provider, '#execute_query' do

  before do
    @provider = OData::Provider.new Dog
    Dog.all_dogs = [
      Dog.new(:id => 1, :name => 'Rover'),
      Dog.new(:id => 2, :name => 'Lander'),
      Dog.new(:id => 3, :name => 'Murdoch'),
      Dog.new(:id => 4, :name => 'Spot'),
      Dog.new(:id => 5, :name => 'Rex')
    ]
  end

  it '/Dogs' do
    dogs = @provider.execute_query @provider.build_query('/Dogs')
    dogs.length.should == 5
  end

  it '/Dogs(3)' do
    dogs = @provider.execute_query @provider.build_query('/Dogs(3)')
    dogs.length.should == 1
    dogs.first.id.should == 3
    dogs.first.name.should == 'Murdoch'
  end

  it '/Dogs?$top=2' do
    dogs = @provider.execute_query @provider.build_query('/Dogs?$top=2')
    dogs.length.should == 2
    dogs.first.id.should == 1
    dogs.first.name.should == 'Rover'
    dogs.last.id.should == 2
    dogs.last.name.should == 'Lander'
  end

  it '/Dogs?$top=2$skip=4' do
    dogs = @provider.execute_query @provider.build_query('/Dogs?$top=2&$skip=4')
    dogs.length.should == 1
    dogs.first.id.should == 5
    dogs.first.name.should == 'Rex'
  end

  it '/Dogs?$top=2$skip=3' do
    dogs = @provider.execute_query @provider.build_query('/Dogs?$top=2&$skip=3')
    dogs.length.should == 2
    dogs.first.id.should == 4
    dogs.first.name.should == 'Spot'
    dogs.last.id.should == 5
    dogs.last.name.should == 'Rex'
  end
end
