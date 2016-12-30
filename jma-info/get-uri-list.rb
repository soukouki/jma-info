
require "nokogiri"

class UriAndTitle
	attr_accessor :uri, :title
	def initialize
		yield(self)
	end
	
	def eql? pair
		uri == pair.uri && title == pair.title
	end
	def hash
		uri.hash + title.hash
	end
end

# 古いものを上にして表示する
def get_uri_list
	Nokogiri::HTML(open("http://api.aitc.jp/jmardb/"), nil, "UTF-8")
		.xpath("/html/body/div[3]/table/tr[position()!=1]")
		.map do |tr|
			UriAndTitle.new do |a|
				a.uri = File.join("http://api.aitc.jp/jmardb/", tr.xpath("td[6]/a/@href").text.split(";")[0])
				a.title = tr.xpath("td[6]/a").text
			end
		end
		.reverse
end
