require 'spec_helper'

# I have no idea how I really want to do this ... just playing with syntax ...

module InitializedByAttributes
  def initialize options = nil
    initialize_with options
  end

  def initialize_with options = nil
    options.each {|key, value| send("#{key}=", value) if respond_to?("#{key}=") } if options
  end
end

module OData
  class Property
    include InitializedByAttributes
    attr_accessor :name, :type
  end

  class EntityBase
    def self.inherited base
      base.send :extend, EntityClassMethods
    end
  end

  module EntityClassMethods
    attr_writer :properties, :entry_type_name

    def properties
      @properties ||= []
    end

    def property name, type
      properties << OData::Property.new(:name => name, :type => type)
    end

    def entry_type_name
      @entry_type_name ||= self.name
    end
  end

  module Entity
    def self.included base
      base.send :extend, ClassMethods
      klass = Class.new(OData::EntityBase)
      base.const_set 'ODataEntity', klass
      base.odata = klass
      base.odata.entry_type_name = base.name
    end

    module ClassMethods
      attr_accessor :odata
    end
  end
end

class Dog < OData::EntityBase
end

class Cat
  include OData::Entity
end

describe OData::EntityBase do

  it 'has #properties' do
    Dog.properties.should be_empty
    Dog.property :name, String
    Dog.properties.should_not be_empty
    Dog.properties.length.should == 1
    Dog.properties.first.name.should == :name
    Dog.properties.first.type.should == String
    Dog.entry_type_name.should == "Dog"
  end

end

describe OData::Entity do

  it 'has #odata.properties' do
    Cat.odata.properties.should be_empty
    Cat.odata.property :foo, Fixnum
    Cat.odata.properties.should_not be_empty
    Cat.odata.properties.length.should == 1
    Cat.odata.properties.first.name.should == :foo
    Cat.odata.properties.first.type.should == Fixnum
    Cat.odata.entry_type_name.should == "Cat"
  end

end
