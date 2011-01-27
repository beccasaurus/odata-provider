module OData
  class Provider
    module Rack

      # Rack application for responding to routes using an OData::Provider
      class Application
        attr_accessor :provider

        def initialize provider
          self.provider = provider
        end

        def call env
          request  = ::Rack::Request.new env
          response = ::Rack::Response.new

          if env['REQUEST_URI'] == '' or env['REQUEST_URI'] == '/'
            response.headers['Content-Type'] = 'application/xml'
            response.write provider.root_xml
            return response.finish
          end

          if env['REQUEST_URI'] == '/$metadata'
            response.headers['Content-Type'] = 'application/xml'
            response.write provider.metadata_xml
            return response.finish
          end

          query    = provider.build_query env['REQUEST_URI'] # has path and query strings
          entities = provider.execute_query query

          if entities.nil?
            response.status = 404
            return response.finish
          end

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
            response.headers['Content-Type'] = 'application/xml'
            response.write provider.xml_for query, entities
          end

          response.finish
        end
      end
    end
  end
end
