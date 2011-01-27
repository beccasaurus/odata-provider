module OData

  # Represents an OData provider
  class Provider

    attr_accessor :entity_types

    def initialize *entity_types
      self.entity_types = entity_types
    end

    def rack_application
      OData::Provider::Rack::Application.new self
    end

    def entity_type_names
      entity_types.map {|type| type.name }
    end

    def get_entity_type name
      entity_types.detect {|type| type.name == name }
    end

    def build_query resource_path
      OData::Query.new :provider => self, :uri => uri_for(resource_path)
    end

    def execute_query query
      query.entity_type.query_executor.execute_query query
    end

    def execute query
      execute_query build_query(query)
    end

    def root_xml
      xml = Nokogiri::XML::Builder.new { |xml|

        xml.service 'xml:base'   => 'http://www.pluralsight-training.net/odata/', 
                    'xmlns:atom' => 'http://www.w3.org/2005/Atom', 
                    'xmlns:app'  => 'http://www.w3.org/2007/app',
                    'xmlns'      => 'http://www.w3.org/2007/app' do |service|

          service.workspace do |workspace|
            workspace.send 'atom:title', 'Default'

            entity_types.each do |entity_type|
              workspace.collection :href => entity_type.collection_name do |collection|
                collection.send 'atom:title', entity_type.collection_name
              end
            end
          end
        end

      }.to_xml.sub('<?xml version="1.0"?>', '<?xml version="1.0" encoding="iso-8859-1" standalone="yes"?>')
    end

    def metadata_xml
      xml = Nokogiri::XML::Builder.new { |xml|

        xml.send 'edmx:Edmx', 'Version' => '1.0', 'xmlns:edmx' => 'http://schemas.microsoft.com/ado/2007/06/edmx' do |edmx|
          edmx.send 'edmx:DataServices', 'xmlns:m' => 'http://schemas.microsoft.com/ado/2007/08/dataservices/metadata', 
                                         'm:DataServiceVersion' => '2.0' do |dataServices|
            dataServices.Schema 'Namespace' => 'MyNamespace', 
                                    'xmlns:d' => 'http://schemas.microsoft.com/ado/2007/08/dataservices',
                                    'xmlns:m' => 'http://schemas.microsoft.com/ado/2007/08/dataservices/metadata',
                                    'xmlns'   => 'http://schemas.microsoft.com/ado/2007/05/edm' do |schema|

              entity_types.each do |entity_type|
                schema.EntityType 'Name' => entity_type.name do |type|

                  type.Key do |key_element|
                    entity_type.keys.each do |key|
                      key_element.PropertyRef 'Name' => key.name
                    end
                  end

                  entity_type.properties.each do |property|
                    type.Property 'Name' => property.name
                  end

                end
              end
            end
          end
        end

      }.to_xml.sub('<?xml version="1.0"?>', '<?xml version="1.0" encoding="iso-8859-1" standalone="yes"?>')
    end

    # @private
    def _build_entity_xml query, entity, entry
      entry.id_ "[root] #{query.uri.path}"
      entry.title '', :type => 'text'
      entry.updated 'xml date'
      entry.author {|a| a.name }

      # <link rel="edit" title="Breed" href="Breeds(1)" />
      # <link rel="http://schemas.microsoft.com/ado/2007/08/dataservices/related/Dogs" type="application/atom+xml;type=feed" title="Dogs" href="Breeds(1)/Dogs" />

      entry.category :term => query.entity_type.name, :scheme => 'http://schemas.microsoft.com/ado/2007/08/dataservices/scheme'

      entry.content(:type => 'application/xml'){ |content|
        content.send('m:properties'){ |properties|
          query.entity_type.properties.each do |property|
            properties.send("d:#{property.name}", entity.send(property.name).to_s)
          end
        }
      }
    end

    def xml_for query, result
      xml = Nokogiri::XML::Builder.new { |xml|

        if query.returns_collection?
          xml.feed 'xml:base' => 'http://localhost:59671/Animals.svc/',
                   'xmlns:d'  => 'http://schemas.microsoft.com/ado/2007/08/dataservices',
                   'xmlns:m'  => 'http://schemas.microsoft.com/ado/2007/08/dataservices/metadata',
                   'xmlns'    => 'http://www.w3.org/2005/Atom' do |feed|

            feed.title query.collection_name, :type => 'text'
            feed.id_ "[ROOT]/#{query.collection_name}"
            feed.updated 'updated date'
            feed.link :rel => 'self', :title => query.collection_name, :href => query.collection_name

            result.each do |entity|
              feed.entry do |entry|
                _build_entity_xml query, entity, entry
              end
            end
          end
        else
          xml.entry 'xml:base' => 'http://localhost:59671/Animals.svc/', 
                    'xmlns:d'  => 'http://schemas.microsoft.com/ado/2007/08/dataservices',
                    'xmlns:m'  => 'http://schemas.microsoft.com/ado/2007/08/dataservices/metadata',
                    'xmlns'    => 'http://www.w3.org/2005/Atom' do |entry|
            _build_entity_xml query, result, entry
          end
        end

      }.to_xml.sub('<?xml version="1.0"?>', '<?xml version="1.0" encoding="utf-8" standalone="yes"?>')
    end

  private

    def uri_for resource_path
      resource_path = resource_path.strip
      resource_path = resource_path.sub('/', '') if resource_path.start_with?('/')
      URI.parse resource_path
    end
  end
end
