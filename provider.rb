require 'uri'
require 'rubygems'
require 'active_support/inflector'
require 'rack'

module InitializedByAttributes
  def initialize options = nil
    initialize_with options
  end

  def initialize_with options = nil
    options.each {|key, value| send("#{key}=", value) if respond_to?("#{key}=") } if options
  end
end

module ArrayToHash
  def to_hash
    self.inject({}){|hash, array| hash[array.first] = array.last; hash }
  end
end

Array.send :include, ArrayToHash

module HashToHash
  def to_hash() self end
end

Hash.send :include, HashToHash

module OData

  # this should define all of the methods QueryExecutors should execute and raise exceptions or warnings or 
  # something that will be useful to people implementing a QueryExecutor.  maybe?
  class QueryExecutor
    def execute_query query
      raise "You must implement #execute_query in your QueryExecutor class (#{self.class.name})"
    end
  end

  # QueryExecutor that works with a regular old array of (EntityType) ruby objects.
  # It will eventually work with REGULAR Ruby objects, assuming they have EntityTypes defined for them ...
  class RubyQueryExecutor < QueryExecutor

    def initialize &block_to_get_all_entities
      @block_to_get_all_entities = block_to_get_all_entities
    end

    def all_entities query
      if @block_to_get_all_entities
        @block_to_get_all_entities.call(query.entity_type)
      else
        query.entity_type.all_entities
      end
    end

    def execute_query query
      all = all_entities(query)
      query.options.each do |option|
        all = filter_with_option all, option, query
      end
      all
    end

    def filter_with_option all, option, query
      case option
      when OData::KeyQueryOption
        return all.select {|entity| entity.send(query.entity_type.keys.first.name).to_s == option.value.to_s }
      when OData::TopQueryOption
        return all[0..(option.value.to_i-1)]
      when OData::SkipQueryOption
        option.value.to_i.times { all.shift }
        all
      else
        raise "Unsupported option type #{option.class.name} for RubyQueryExecutor"
      end 
    end
  end

  class Query
    include InitializedByAttributes

    attr_accessor :provider, :uri, :entity_type, :options

    def options
      @options ||= []
    end

    def query_strings
      Rack::Utils.parse_query(uri.query).select {|key, value| key.start_with?('$') }.to_hash
    end

    class << self
      attr_accessor :option_types
      attr_accessor :executor_types
      attr_accessor :default_executor_type
    end

    @option_types   ||= []
    @executor_types ||= {}
  end

  class QueryOption
    include InitializedByAttributes

    attr_accessor :value

    def self.add_option_to_query query
      raise "You must implement #add_option_to_query in your OData::Query class (#{self.class.name})"
    end

    def self.inherited base
      Query.option_types.unshift base
    end
  end

  class OData::KeyQueryOption < OData::QueryOption
    def self.add_option_to_query query
      first_part = query.uri.path.split('/').first
      if first_part =~ /^(\w+)\(([^\)]+)\)/ # Dogs(1)
        entity_name, key = $1, $2
        query.options << OData::KeyQueryOption.new(:value => key)
      end
    end
  end

  class OData::TopQueryOption < OData::QueryOption
    def self.add_option_to_query query
      if top = query.query_strings['$top']
        query.options << OData::TopQueryOption.new(:value => top)
      end
    end
  end

  class OData::SkipQueryOption < OData::QueryOption
    def self.add_option_to_query query
      if skip = query.query_strings['$skip']
        query.options << OData::SkipQueryOption.new(:value => skip)
      end
    end
  end

  class Provider

    module Rack
      class Middleware
        attr_accessor :app, :provider, :service_root

        def initialize app, options
          self.app          = app
          self.provider     = options[:provider]
          self.service_root = options[:service_root]

          service_root.sub /\/$/, '' if service_root.end_with? '/'
        end

        def provider_app
          #@provider_app ||= provider.rack_application
          @provider_app ||= OData::Provider::Rack::Application.new(provider)
        end

        def remove_service_root! env
          env['PATH_INFO'].sub!    service_root, ''
          env['REQUEST_URI'].sub!  service_root, ''
          env['REQUEST_PATH'].sub! service_root, ''
        end

        def call env
          if env['PATH_INFO'].start_with? service_root
            remove_service_root! env
            provider_app.call    env
          else
            app.call env
          end
        end
      end

      class Application
        attr_accessor :provider

        def initialize provider
          self.provider = provider
        end

        def call env
          request  = ::Rack::Request.new env
          response = ::Rack::Response.new
          entities = provider.execute env['REQUEST_URI'] # has path and query strings

          case request.GET['format']
          when 'yaml'
            require 'yaml'
            response.headers['Content-Type'] = 'text/plain'
            response.write entities.to_yaml
          when 'xml'
            require 'active_support/all'
            response.headers['Content-Type'] = 'application/xml'
            response.write entities.to_xml
          when 'json'
            require 'active_support/json'
            response.headers['Content-Type'] = 'application/json'
            response.write ActiveSupport::JSON.encode(entities)
          else
            response.write 'going to write custom xml ...'
          end

          response.finish
        end
      end
    end

    attr_accessor :entity_types

    def initialize *entity_types
      self.entity_types = entity_types
    end

    def entity_type_names
      entity_types.map {|type| type.name }
    end

    def get_entity_type name
      entity_types.detect {|type| type.name == name }
    end

    def build_query resource_path
      uri         = uri_for resource_path
      entity_type = entity_type_for uri.path
      query       = OData::Query.new :provider => self, :uri => uri, :entity_type => entity_type

      OData::Query.option_types.each do |option_type|
        option_type.add_option_to_query query
      end

      query
    end

    def execute_query query
      query.entity_type.query_executor.execute_query query
    end

    def execute query
      execute_query build_query(query)
    end

  private

    def uri_for resource_path
      resource_path = resource_path.strip
      resource_path = resource_path.sub('/', '') if resource_path.start_with?('/')
      URI.parse resource_path
    end

    def entity_type_for path
      get_entity_type path.split('/').first.sub(/\([^\)]*\)$/, '').singularize
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

    def properties
      self.class.properties.inject({}) do |hash, property|
        hash[property.name] = send(property.name) if respond_to?(property.name)
        hash
      end
    end

    # Assumes activesupport xml serialization ...
    def to_xml options = {}
      properties.to_xml options
    end

    def self.keys
      @keys ||= []
    end
    
    def self.properties
      @properties ||= []
    end

    def self.query_executor
      @query_executor || Query.default_executor_type.new
    end

    def self.query_executor= query_executor
      @query_executor = query_executor
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

    def self.executor name_or_instance, *args, &block
      if executor_type = Query.executor_types[name_or_instance]
        self.query_executor = executor_type.new(*args, &block)
      else
        self.query_executor = name_or_instance
      end
    end
  end
end

# Setup default OData query options
OData::Query.option_types = [OData::KeyQueryOption, OData::SkipQueryOption, OData::TopQueryOption]

# Register names query executors
OData::Query.executor_types = { :ruby => OData::RubyQueryExecutor }

# Set a default executor, incase none is specified
OData::Query.default_executor_type = OData::RubyQueryExecutor
