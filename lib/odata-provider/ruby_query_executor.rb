module OData

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

      # nil should be returned if no results
      return nil if all.empty?

      # otherwise, return either an array or an entity
      query.returns_collection? ? all : all.first
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
end
