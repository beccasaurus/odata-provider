$LOAD_PATH.unshift File.dirname(__FILE__)

%w[ rubygems active_support/inflector rack nokogiri ].each {|lib| require lib }

require 'odata-provider/extensions'

# OData namespace
module OData
end

require 'odata-provider/initialized_by_attributes'
require 'odata-provider/query_executor'
require 'odata-provider/ruby_query_executor'
require 'odata-provider/query'
require 'odata-provider/query_option'
require 'odata-provider/key_query_option'
require 'odata-provider/top_query_option'
require 'odata-provider/skip_query_option'
require 'odata-provider/provider'
require 'odata-provider/provider/rack/middleware'
require 'odata-provider/provider/rack/application'
require 'odata-provider/entity_key'
require 'odata-provider/entity_property'
require 'odata-provider/entity_type'

# Setup default OData query options
OData::Query.option_types = [OData::KeyQueryOption, OData::SkipQueryOption, OData::TopQueryOption]

# Register names query executors
OData::Query.executor_types = { :ruby => OData::RubyQueryExecutor }

# Set a default executor, incase none is specified
OData::Query.default_executor_type = OData::RubyQueryExecutor
