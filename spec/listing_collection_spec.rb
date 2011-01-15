require 'spec_helper'
require 'uri'

class SavedResponse
  attr_accessor :uri, :body

  def initialize filename
    response_file    = File.join File.dirname(__FILE__), 'animals-example', 'responses', filename
    content          = File.read response_file
    http_index       = content.index 'HTTP'
    self.uri         = URI.parse content[0..http_index-1].strip
    headers_and_body = content[http_index..-1].split("\r\n\r\n")
    @raw_headers     = headers_and_body.shift.strip
    self.body        = headers_and_body.join("\n")
  end

  def path
    uri.path
  end

  def url
    url.to_s
  end

  def headers
    @raw_headers.split("\n").map {|text| text.strip }.inject({}) do |all, this|
      unless this.start_with? 'HTTP'
        colon    = this.index(':')
        key      = this[0..colon-1].strip
        value    = this[colon+1..-1].strip
        all[key] = value
      end
      all
    end
  end
end

def saved_response filename
  SavedResponse.new filename
end

# describe 'Listing Collection' do
# 
#   it 'GET /Animals.svc/Dogs [application/atom+xml]' do
#     header 'Accept', 'application/atom+xml'
#     get '/Animals.svc/Dogs'
# 
#     last_response.body.should == saved_response('Dogs.xml').body
#   end
# 
# end
