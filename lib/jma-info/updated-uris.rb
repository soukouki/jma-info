
require "open-uri"
require "json"

# @uris すでに取得しているuri
# @get_back aitc側の更新が2-3分遅れるので、その分の設定と、起動時に少し遡って表示する時間
class UrisCache
	private def initialize(uris, get_back)
		@uris = uris
		@get_back = get_back
	end
	
	def self::NewCache(get_back)
		UrisCache.new([], get_back)
	end
	
	# return [0] 取得したuri
	# return [1] 新しいUrisCache
	def updated_uris(now_time)
		new_uris = UrisCache::get_uri_list(now_time-@get_back, now_time)
		[new_uris-@uris, UrisCache.new(@uris | new_uris, @get_back)]
	end
	
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
			get_items(uri).map{|h|h["link"]}
		end
	end
end
