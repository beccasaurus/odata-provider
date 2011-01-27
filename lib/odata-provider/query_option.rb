module OData

  # Base class for QueryOption classes.
  #
  # Right now, all this does is raise an informative exception if you forget to implement 
  # the required QueryOption methods in your QueryOption implementation.
  #
  # Plus it gives you a #value attribute for storing the value of this QueryOption to be used 
  # when the option is processed / executed.
  class QueryOption
    include InitializedByAttributes

    attr_accessor :value

    def self.add_option_to_query query
      raise "You must implement #add_option_to_query in your OData::Query class (#{self.class.name})"
    end

    def self.inherited base
      OData::Query.option_types.unshift base
    end
  end
end
