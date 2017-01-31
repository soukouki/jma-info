
require "open-uri"
require "json"

UriAndTitle = Struct.new(:uri, :title)

def time_format time
	time.strftime("%FT%T")
end

def get_items uri
	data = JSON.parse(OpenURI.open_uri(uri).read)
	if data["paging"]["next"].nil?
		data["data"]
	else
		sleep(0.5) # 念のため少し間を空けておく
		data["data"]+get_items(data["paging"]["next"])
	end
end

# 古いものを上にして表示する
def get_uri_list old_date, new_date
	uri =
		"http://api.aitc.jp/jmardb-api/search?"+
		"datetime=#{time_format(old_date)}&datetime=#{time_format(new_date)}&limit=100"
	get_items(uri)
		.map{|h|UriAndTitle.new(h["link"], h["title"])}
end
