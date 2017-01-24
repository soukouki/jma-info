
require "open-uri"
require "json"

UriAndTitle = Struct.new(:uri, :title)

def time_format time
	time.strftime("%F %T")
end

def get_json uri
	data = JSON.parse(OpenURI.open_uri(uri).read)
	if data["paging"]["next"].nil?
		data["data"]
	else
		data["data"]+get_json(data["paging"]["next"])
	end
end

# 古いものを上にして表示する
def get_uri_list old_date, new_date
	get_json(
		"http://api.aitc.jp/jmardb-api/search?"+
		"datetime=#{time_format(old_date)}&datetime=#{time_format(new_date)}&limit=100")
		.map{|h|UriAndTitle.new(h["link"], h["title"])}
end
