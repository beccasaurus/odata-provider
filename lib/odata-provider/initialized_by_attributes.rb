module OData

  # Give your class a conventional Ruby constructor that takes a 
  # Hash of attributes and sets instance attributes accordingly.
  module InitializedByAttributes

    def initialize options = nil
      initialize_with options
    end

    def initialize_with options = nil
      options.each {|key, value| send("#{key}=", value) if respond_to?("#{key}=") } if options
    end
  end
end
