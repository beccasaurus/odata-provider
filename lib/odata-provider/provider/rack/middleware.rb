module OData
  class Provider
    module Rack

      # Rack middleware for letting an OData::Provider handle responses to routes that start with a given service_root
      #
      #   use OData::Provider::Rack::Middleware, :provider => OData::Provider.new(Dog, Cat), :service_root => '/Animals.svc'
      #
      # This delegates actual responses to an OData::Provider::Rack::Application that it creates.
      class Middleware
        attr_accessor :app, :provider, :service_root

        def initialize app, options
          self.app          = app
          self.provider     = options[:provider]
          self.service_root = options[:service_root]

          service_root.sub /\/$/, '' if service_root.end_with? '/'
        end

        def provider_app
          @provider_app ||= provider.rack_application
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
    end
  end
end
