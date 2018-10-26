

class JmaInfoGetter
	SOURCE_URIS =
		[
			"https://www.data.jma.go.jp/developer/xml/feed/eqvol.xml", # 地震火山
			"https://www.data.jma.go.jp/developer/xml/feed/regular.xml", # 定時
			"https://www.data.jma.go.jp/developer/xml/feed/extra.xml", # 随時
			"https://www.data.jma.go.jp/developer/xml/feed/other.xml", # その他
		]
	
	def initialize &block
		@loop_thread = Thread.new{JmaInfoGetter.main_loop(block)}
	end
	
	def sync
		@loop_thread.join
	end
	
	class << self
		
		def main_loop callback
			older_urls = get_uris
			loop do
				sleep(60 - Time.now.sec + 3) # 1-2秒程度更新のラグがあるため
				get_uris_ = get_uris
				new_uris = get_uris_ - older_urls
				older_urls = get_uris_
				callback.call(new_uris.reverse) # そのままだと新しいものが上に来るため
			end
		end
		
		def get_uris
			SOURCE_URIS
				.map do |uri|
					begin
						RSS::Parser.parse(OpenURI::open_uri(uri))
					rescue RSS::NotWellFormedError
						puts "データ取得エラー #{uri}"
						nil
					end
				end
				.delete_if{|atom|atom.nil?}
				.map{|atom|atom.items.map{|item|item.link.href}}
				.flatten
		end
		
	end
	
end
