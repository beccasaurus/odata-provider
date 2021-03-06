#require 'spec_helper'
require File.dirname(__FILE__) + '/../lib/odata/provider'

class Dog < OData::EntityType
  include OData::InitializedByAttributes

  key :id

  attr_property :id,   String
  attr_property :name, String

  executor :ruby

  # conventional method for the RubyQueryExecutor
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

describe OData::Provider, '#execute' do

  before do
    @provider = OData::Provider.new Dog
  end

  it 'raises exception is #entity_types does not include the type'

  it '/Dogs' do
    dogs = @provider.execute('/Dogs')
    dogs.length.should == 5
  end

  it '/Dogs(3)' do
    dog = @provider.execute('/Dogs(3)')
    dog.id.should == 3
    dog.name.should == 'Murdoch'
  end

  it '/Dogs?$top=2' do
    dogs = @provider.execute('/Dogs?$top=2')
    dogs.length.should == 2
    dogs.first.id.should == 1
    dogs.first.name.should == 'Rover'
    dogs.last.id.should == 2
    dogs.last.name.should == 'Lander'
  end

  it '/Dogs?$top=2$skip=4' do
    dogs = @provider.execute('/Dogs?$top=2&$skip=4')
    dogs.length.should == 1
    dogs.first.id.should == 5
    dogs.first.name.should == 'Rex'
  end

  it '/Dogs?$top=2$skip=3' do
    dogs = @provider.execute('/Dogs?$top=2&$skip=3')
    dogs.length.should == 2
    dogs.first.id.should == 4
    dogs.first.name.should == 'Spot'
    dogs.last.id.should == 5
    dogs.last.name.should == 'Rex'
  end

end

describe OData::Provider, '#make_query' do

  before do
    @provider = OData::Provider.new Dog
  end

  it '/Dogs' do
    query = @provider.build_query '/Dogs'
    query.entity_type.should == Dog
    query.options.should be_empty
    query.returns_collection?.should be_true
    query.returns_entity?.should     be_false
    query.collection_name.should == 'Dogs'
    query.entity_name.should     == 'Dog'
  end

  it '/Dogs(1)' do
    query = @provider.build_query '/Dogs(1)'
    query.entity_type.should == Dog
    query.options.length.should == 1
    query.options.first.should be_a(OData::QueryOption)
    query.options.first.should be_a(OData::KeyQueryOption)
    query.options.first.value.should == '1'
    query.returns_collection?.should be_false
    query.returns_entity?.should     be_true
    query.collection_name.should == 'Dogs'
    query.entity_name.should     == 'Dog'
  end

  it '/Dogs?$top=2' do
    query = @provider.build_query '/Dogs?$top=2'
    query.entity_type.should == Dog
    query.options.length.should == 1
    query.options.first.should be_a(OData::QueryOption)
    query.options.first.should be_a(OData::TopQueryOption)
    query.options.first.value.should == '2'
    query.returns_collection?.should be_true
    query.returns_entity?.should     be_false
    query.collection_name.should == 'Dogs'
    query.entity_name.should     == 'Dog'
  end

  it '/Dogs?$top=2$skip=5' do
    query = @provider.build_query '/Dogs?$top=2&$skip=5'
    query.entity_type.should == Dog
    query.options.length.should == 2
    top_option = query.options.detect  {|o| o.is_a? OData::TopQueryOption }
    top_option.value.should == '2'
    skip_option = query.options.detect {|o| o.is_a? OData::SkipQueryOption }
    skip_option.value.should == '5'
    query.returns_collection?.should be_true
    query.returns_entity?.should     be_false
    query.collection_name.should == 'Dogs'
    query.entity_name.should     == 'Dog'
  end

end

describe OData::Provider, '#execute_query' do

  before do
    @provider = OData::Provider.new Dog
  end

  it '/Dogs' do
    dogs = @provider.execute_query @provider.build_query('/Dogs')
    dogs.should be_a(Array)
    dogs.length.should == 5
  end

  it '/Dogs(3)' do
    dog = @provider.execute_query @provider.build_query('/Dogs(3)')
    dog.should be_a(Dog)
    dog.id.should == 3
    dog.name.should == 'Murdoch'
  end

  it '/Dogs?$top=2' do
    dogs = @provider.execute_query @provider.build_query('/Dogs?$top=2')
    dogs.should be_a(Array)
    dogs.length.should == 2
    dogs.first.id.should == 1
    dogs.first.name.should == 'Rover'
    dogs.last.id.should == 2
    dogs.last.name.should == 'Lander'
  end

  it '/Dogs?$top=2$skip=4' do
    dogs = @provider.execute_query @provider.build_query('/Dogs?$top=2&$skip=4')
    dogs.should be_a(Array)
    dogs.length.should == 1
    dogs.first.id.should == 5
    dogs.first.name.should == 'Rex'
  end

  it '/Dogs?$top=2$skip=3' do
    dogs = @provider.execute_query @provider.build_query('/Dogs?$top=2&$skip=3')
    dogs.should be_a(Array)
    dogs.length.should == 2
    dogs.first.id.should == 4
    dogs.first.name.should == 'Spot'
    dogs.last.id.should == 5
    dogs.last.name.should == 'Rex'
  end
end

describe OData::Provider, '#render' do

  before do
    @provider = OData::Provider.new Dog
  end

  it '/Dogs' do
    pending
    xml = @provider.render('/Dogs')
  end

  it '/Dogs(3)' do
    pending
    xml = @provider.render('/Dogs(3)')
  end

  it '/Dogs?$top=2' do
    pending
    xml = @provider.render('/Dogs?$top=2')
  end

  it '/Dogs?$top=2$skip=4' do
    pending
    xml = @provider.render('/Dogs?$top=2&$skip=4')
  end

  it '/Dogs?$top=2$skip=3' do
    pending
    xml = @provider.render('/Dogs?$top=2&$skip=3')
  end

end
