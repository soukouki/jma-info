
public def test x, msg
	if self!=x
		puts "not ok #{self}!=#{x} #{msg}"
	else
		print("o")
	end
end

def get_uri_list(time, traceback)
	uc = UrisCache::NewCache(traceback)
	uc.updated_uris(time)[0]
end

get_uri_list(Time.new(2017, 1, 1, 23, 0, 0), 3600).length.test 6, "データが取得できるか"
get_uri_list(Time.new(2016, 12, 31, 16, 40, 0), 60*10).length.test 144, "データが多くても処理できるか"

get_uri_list(Time.new(2017, 1, 24, 22, 48, 20), 10).test(
	["http://api.aitc.jp/jmardb-api/reports/301a10b4-c540-372c-9db3-1457664031cd"],"そのデータの確認")

puts ""
