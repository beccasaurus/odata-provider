module OData
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

    def self.collection_name
      self.name.pluralize
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
