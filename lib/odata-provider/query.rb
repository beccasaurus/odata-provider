module OData

  # Has a Provider and a Uri that it uses to determine entity_type, options, return type, etc
  class Query
    include InitializedByAttributes

    class << self
      attr_accessor :option_types
      attr_accessor :executor_types
      attr_accessor :default_executor_type
    end

    @option_types   ||= []
    @executor_types ||= {}

    attr_accessor :provider, :uri, :options

    def initialize options = nil
      super

      OData::Query.option_types.each do |option_type|
        option_type.add_option_to_query self
      end
    end

    def options
      @options ||= []
    end

    def query_strings
      Rack::Utils.parse_query(uri.query).select {|key, value| key.start_with?('$') }.to_hash
    end

    def collection_name
      uri.path.split('/').last.sub(/\([^\)]*\)$/, '')
    end

    def entity_type
      provider.get_entity_type collection_name.singularize
    end

    def entity_name
      entity_type.name
    end

    def returns_collection?
      last_part_of_path = uri.path.split('/').last
      last_part_of_path == last_part_of_path.pluralize
    end

    def returns_entity?
      not returns_collection?
    end
  end
end
