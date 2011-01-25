#! /usr/bin/env ruby
require 'rubygems'
# require 'builder'
require 'nokogiri'

#puts Nokogiri::XML::Builder.new(:encoding => 'utf-8', :standalone => 'yes'){ |xml|
#  xml.hi 'there'
#}.to_xml

# <entry xml:base="http://localhost:59671/Animals.svc/" xmlns:d="http://schemas.microsoft.com/ado/2007/08/dataservices" xmlns:m="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" xmlns="http://www.w3.org/2005/Atom">

# NOTE can't seem to get Nokogiri's XML Builder to write the instruct! like i want, so we'll replace it manually ...
puts Nokogiri::XML::Builder.new { |xml|
  xml.entry 'xml:base' => 'http://localhost:59671/Animals.svc/', 
            'xmlns:d'  => 'http://schemas.microsoft.com/ado/2007/08/dataservices',
            'xmlns:m'  => 'http://schemas.microsoft.com/ado/2007/08/dataservices/metadata',
            'xmlns'    => 'http://www.w3.org/2005/Atom' do |entry|

    entry.id_ 'hi'
    entry.title 'the title', :type => 'text'
  end
}.to_xml

__END__
  <id>http://localhost:59671/Animals.svc/Breeds(1)</id>^M
  <title type="text"></title>^M
  <updated>2011-01-14T23:24:28Z</updated>^M
  <author>^M
    <name />^M
  </author>^M
  <link rel="edit" title="Breed" href="Breeds(1)" />^M
  <link rel="http://schemas.microsoft.com/ado/2007/08/dataservices/related/Dogs" type="application/atom+xml;type=feed" title="Dogs" href="Breeds(1)/Dogs" />^M
  <category term="AnimalsDataModel.Breed" scheme="http://schemas.microsoft.com/ado/2007/08/dataservices/scheme" />^M
  <content type="application/xml">^M
    <m:properties>^M
      <d:Id m:type="Edm.Int32">1</d:Id>^M
      <d:Name>Goldern Retriever</d:Name>^M
    </m:properties>^M
  </content>^M
