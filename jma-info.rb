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
	trs = doc.xpath("/html/body/div[3]/table/tr[position()!=1]")
	trs.map do |tr|
		UriAndTitle.new do |a|
			a.uri = File.join("http://api.aitc.jp/jmardb/", tr.xpath("td[6]/a/@href").text.split(";")[0])
			a.title = tr.xpath("td/a").text
		end
	end
end

def sleep_up_to_even_number_minutes
	sleep(((Time.now.min+1)%2*60)+(60-Time.now.sec))
end

old_uris = get_uri_list
loop do
	puts Time.now
	new_uris = get_uri_list
	puts new_uris - old_uris
	old_uris = new_uris
	sleep_up_to_even_number_minutes
end
