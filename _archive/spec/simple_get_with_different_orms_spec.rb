require 'spec_helper'

$database_path = File.join File.dirname(__FILE__), 'animals-example', 'animals.sqlite3'

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => $database_path
module AR
  class Dog < ActiveRecord::Base
  end
end

describe 'Simple Get with different ORMs' do

  describe 'Query Parsing' do

    it '/Dogs' do
      query = OData::Provider.parse_query '/Dogs'
      query.collection_name.should == 'Dogs'
      query.options.should be_empty
    end

    it '/Dogs(2)' do
      query = OData::Provider.parse_query '/Dogs'
      query.collection_name.should == 'Dogs'
      query.options.length.should == 1
      query.options.first.should be_a(OData::QueryOption)
      query.options.first.should be_a(OData::KeyQueryOption)
      query.options.first.value.should == { :Id => 2 }
    end

    it '/Dogs?$top=5' do
      query = OData::Provider.parse_query '/Dogs'
      query.collection_name.should == 'Dogs'
      query.options.length.should == 1
      query.options.first.should be_a(OData::QueryOption)
      query.options.first.should be_a(OData::TopQueryOption)
      query.options.first.value.should == 5
    end

  end

  describe 'ActiveRecord' do

    it '_setup OK_' do
      AR::Dog.count.should == 4
      AR::Dog.first.Name.should == 'Lander'
    end

    it '/Dogs' do
      pending
      AR::Dog.odata.all.count.should == 4
    end

    it '/Dogs(2)' do
      pending
      #AR::Dog.odata.get().all.count.should == 1

    end

    it '/Dogs?$top=5'

  end

end
