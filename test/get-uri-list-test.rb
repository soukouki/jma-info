
require_relative "../jma-info/get-uri-list"

public def test x, msg
	if self!=x
		puts "not ok #{self}!=#{x} #{msg}"
	end
end

get_uri_list(
	Time.new(2017, 1, 1, 22, 0, 0), Time.new(2017, 1, 1, 23, 0, 0)).length.test 6, "データが取得できるか"
get_uri_list(
	Time.new(2016, 12, 31, 16, 30, 0),
	Time.new(2016, 12, 31, 16, 40, 0)).length.test 144, "データが多くても処理できるか"

get_uri_list(Time.new(2017, 1, 24, 22, 48, 10),Time.new(2017, 1, 24, 22, 48, 20)).test(
	[UriAndTitle.new("http://api.aitc.jp/jmardb-api/reports/301a10b4-c540-372c-9db3-1457664031cd", "府県天気概況")],
	"戻り値の確認")
