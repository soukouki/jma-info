
require "./jma-info/get-uri-list"

public def test x, msg
	if self!=x
		puts "失敗 #{self}!=#{x} #{msg}"
	end
end

get_uri_list(
	Time.new(2017, 1, 1, 22, 0, 0), Time.new(2017, 1, 1, 23, 0, 0)).length.test 6, "データが取得できるか"
get_uri_list(
	Time.new(2016, 12, 31, 16, 30, 00),
	Time.new(2016, 12, 31, 16, 40, 00)).length.test 144, "データが多くても処理できるか"
