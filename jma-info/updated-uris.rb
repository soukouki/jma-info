
require "open-uri"
require "json"

class UrisCache
	private def initialize(uris, cache_time)
		@uris = uris
		@cache_time = cache_time
	end
	
	def self.NewCache(cache_time, now_time)
		UrisCache.new(UrisCache::get_uri_list(now_time-cache_time, now_time), cache_time)
	end
	
	def updated_uris(now_time)
		new_uris = UrisCache::get_uri_list(now_time-@cache_time, now_time)
		[new_uris-@uris, UrisCache.new(@uris | new_uris, @cache_time)]
	end
	
	UriAndTitle = Struct.new(:uri, :title)
	
	class << self
		def time_to_s time
			time.strftime("%FT%T")
		end
		
		def get_items uri
			begin
				text = OpenURI.open_uri(uri).read
			rescue # ネット関係のエラーは握りつぶす
				STDERR.puts "インターネットでのエラーが発生しました。このまま続行します。"
				return []
			end
			data = JSON.parse(text)
			if data["paging"]["next"].nil?
				data["data"]
			else
				sleep(1) # 念のため少し間を空けておく
				data["data"]+get_items(data["paging"]["next"])
			end
		end
		
		# 古いものを上にして表示する
		def get_uri_list old_time, now_time
			uri =
				"http://api.aitc.jp/jmardb-api/search?"+
				"datetime=#{time_to_s(old_time)}&datetime=#{time_to_s(now_time)}&limit=100"
			get_items(uri)
				.map{|h|UriAndTitle.new(h["link"], h["title"])}
		end
	end
end
