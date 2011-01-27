module OData
  class EntityProperty
    include InitializedByAttributes

    attr_accessor :name, :type
  end
end
