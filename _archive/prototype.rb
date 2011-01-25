%w[ rubygems sinatra ].each {|lib| require lib }

module InitializedByAttributes
  def initialize options = nil
    initialize_with options
  end

  def initialize_with options = nil
    options.each {|key, value| send("#{key}=", value) if respond_to?("#{key}=") } if options
  end
end

require 'uri'
require 'active_support/inflector'
module OData

  class Provider
    attr_accessor :entity_types

    def initialize *entity_types
      self.entity_types = entity_types
    end

    def entity_type_names
      entity_types.map {|type| type.name }
    end

    def execute query
      query = query.strip
      query = query.sub('/', '') if query.start_with?('/')
      uri   = URI.parse query
      query = uri.path

      if query =~ /^(\w+)\(([^\)]+)\)/
        plural_entity_type_name, key = $1, $2
        if entity_type = entity_types.detect {|type| type.name == plural_entity_type_name.singularize }
          entity_type.get key
        else
          "Entity type not found: #{plural_entity_type_name.singularize.inspect}"
        end
      else
        "Query does not have a key: #{query}"
      end
    end
  end

  class EntityKey
    include InitializedByAttributes

    attr_accessor :name
  end

  class EntityProperty
    include InitializedByAttributes

    attr_accessor :name, :type #, ...
  end

  class EntityType
    include InitializedByAttributes

    def self.keys
      @keys ||= []
    end
    
    def self.properties
      @properties ||= []
    end

    def self.key name
      self.keys << EntityKey.new(:name => name)
    end

    def self.property name, type
      self.properties << EntityProperty.new(:name => name, :type => type)
    end

    # Equivalent of:
    #
    #   attr_accessor :foo
    #   property :foo, String
    #
    # Adds an attr_accessor for you.
    #
    def self.attr_property name, type
      property name, type
      attr_accessor name
    end
  end
end

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

$dogs = [
  Dog.new(:id => 1, :name => 'Rover'),
  Dog.new(:id => 2, :name => 'Lander'),
  Dog.new(:id => 3, :name => 'Murdoch')
]

get '/Animals.svc*' do |path|
  content_type 'text/plain'

  query = path
  query += "?#{ request.query_string }" unless request.query_string.empty?

  provider = OData::Provider.new Dog
  objects  = provider.execute query

  "provider.execute(#{query.inspect}) = #{objects.inspect}"
end
