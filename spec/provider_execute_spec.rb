#require 'spec_helper'
require File.dirname(__FILE__) + '/../provider'

class Dog < OData::EntityType
  include InitializedByAttributes

  key :id

  attr_property :id,   String
  attr_property :name, String

  # assumes *1* key for now ...
  def self.get key
    $dogs.detect {|dog| dog.send(keys.first.name).to_s == key.to_s }
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
