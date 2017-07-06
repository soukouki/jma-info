
require "open-uri"
require "rexml/document"

test_source = open("test/get-info.rb", 'r:utf-8').read

ifs = test_source.scan(Regexp.new "http://api.aitc.jp/jmardb/reports/[a-z0-9-]+")

ifs
	.map{|uri|{xml:REXML::Document.new(open(uri).read), uri:uri}}
	.group_by{|g|g[:xml].elements["Report/Control/Title"].text}
	.each{|g|
		g[1].each_with_index{|g, index|
			xml = g[:xml]
			uri = g[:uri]
			fname = "./test/samples/#{xml.elements["Report/Control/Title"].text}-#{index+1}.xml"
			test_source.sub!(Regexp.new uri){fname}
			File::open(fname, "w"){|f|
				f.puts xml.to_s}}}

open("test/get-info.rb", "w"){|f|f.puts test_source}
