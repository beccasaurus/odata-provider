module OData

  # Base class for QueryExecutor classes
  #
  # Right now, all this does is raise an informative exception if you forget to implement 
  # the required QueryExecutor methods in your QueryExecutor implementation
  class QueryExecutor
    def execute_query query
      raise "You must implement #execute_query in your QueryExecutor class (#{self.class.name})"
    end
  end
end
