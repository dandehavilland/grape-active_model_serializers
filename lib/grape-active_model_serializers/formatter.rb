require 'active_record'

module Grape
  module Formatter
    module ActiveModelSerializers
      class << self
        attr_accessor :infer_serializers
        attr_reader :endpoint

        ActiveModelSerializers.infer_serializers = true

        def call(resource, env)
          @endpoint = env["api.endpoint"]

          namespace         = endpoint.settings[:namespace]
          namespace_options = namespace ? namespace.options : {}
          route_options     = endpoint.options[:route_options]
          options           = namespace_options.merge(route_options)

          serializer = serializer(endpoint, resource, options)

          if serializer
            serializer.to_json
          else
            Grape::Formatter::Json.call resource, env
          end
        end

        private

        def serializer(endpoint, resource, options={})
          serializer = options.delete(:serializer) ||
            (resource.respond_to?(:active_model_serializer) &&
             resource.active_model_serializer)

          return serializer unless serializer

          if resource.respond_to?(:to_ary)
            unless serializer <= ActiveModel::ArraySerializer
              raise ArgumentError.new("#{serializer.name} is not an ArraySerializer. " +
                                      "You may want to use the :each_serializer option instead.")
            end

            if options[:root] != false && serializer.root != false
              # the serializer for an Array is ActiveModel::ArraySerializer
              options[:root] ||= serializer.root || resource.first.class.name.underscore.pluralize
            end
          end

          # options[:scope] = controller.serialization_scope unless options.has_key?(:scope)
          # options[:scope_name] = controller._serialization_scope
          # options[:url_options] = controller.url_options

          serializer.new(resource, options)
        end
      end
    end
  end
end
