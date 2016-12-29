# encoding: UTF-8

require "open-uri"

require "nokogiri"

class UriAndTitle
	attr_accessor :uri, :title
	def initialize
		yield(self)
	end
	
	def to_s
		"uri=>#{uri}, title=>#{title}"
	end
	def eql? pair
		uri == pair.uri && title == pair.title
	end
	def hash
		uri.hash + title.hash
	end
end

def get_uri_list
	doc = Nokogiri::HTML(open("http://api.aitc.jp/jmardb/"), nil, 'UTF-8')
	uris = doc.xpath("/html/body/div[3]/table/tr/td[6]/a/@href").map(&:text)
	uris.map do |uri|
		UriAndTitle.new do |a|
			a.uri = File.join("http://api.aitc.jp/jmardb/", uri.split(";")[0])
			a.title = "title"
		end
	end
end

old_uris = get_uri_list
loop do
	puts Time.now
	new_uris = get_uri_list
	puts new_uris - old_uris
	old_uris = new_uris
	sleep(60 - Time.now.sec)
end
