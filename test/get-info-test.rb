
require_relative "../jma-info/get-info"

# テスト側を変えないためにここでincludeしている
def test_group execute, name, &block
	include GetInfo
	if execute
		puts "\n"+name
		block.call
	else
		print "s"
	end
end

test_group(false, "一般報") do
	puts get_general_report("http://api.aitc.jp/jmardb/reports/2be7a5a8-11df-3fa4-954a-0b0b233884d2")
	puts get_general_report("http://api.aitc.jp/jmardb/reports/2f1a794e-12c5-3538-a683-72db002c2b9a")
	puts get_general_report("http://api.aitc.jp/jmardb/reports/7fa44ebf-64a1-32ab-9d99-379de6663211")
end

test_group(false, "概況") do
	puts get_general_weather_conditions("http://api.aitc.jp/jmardb/reports/6220814d-3290-3722-be82-52855f47f800")
end

test_group(false, "注意報") do
	puts get_alerm("http://api.aitc.jp/jmardb/reports/06ec89d7-67b5-3dad-9a54-5544ea0ae02d")
	puts get_alerm("http://api.aitc.jp/jmardb/reports/9f2c7b54-171d-3bab-9c0b-81bdc410db16")
	# 注意報解除
	puts get_alerm("http://api.aitc.jp/jmardb/reports/0854e7f4-44e6-32bf-a78a-500a628cbbdd")
end

test_group(false, "季節観測・特殊気象報") do
	puts get_special_weather_report("http://api.aitc.jp/jmardb/reports/8c13276d-3962-39c4-9344-46416963cd73")
	puts get_special_weather_report("http://api.aitc.jp/jmardb/reports/8ca44e6c-6e97-37e8-81d8-e6576f6752cb")
	puts get_special_weather_report("http://api.aitc.jp/jmardb/reports/b5c0ab67-3e52-3ab3-adbf-395dcf848fa0")
	puts get_special_weather_report("http://api.aitc.jp/jmardb/reports/abfc7ddd-4841-3ae3-9733-4de637a89da9")
	puts get_special_weather_report("http://api.aitc.jp/jmardb/reports/a2b1a4b6-1091-31b8-aaa3-bc6c8a3e801b")
end

test_group(false, "地方海上警報") do
	puts get_local_maritime_alert("http://api.aitc.jp/jmardb/reports/7fdbc660-411a-3568-9025-4dab1777dde0")
	puts get_local_maritime_alert("http://api.aitc.jp/jmardb/reports/9a8468ae-e420-3080-bbad-28146ab507ab")
	puts get_local_maritime_alert("http://api.aitc.jp/jmardb/reports/961acdfc-8019-3b17-98cb-ea947f268d16")
end

test_group(false, "生物季節観測") do
	puts creature_season_observation("http://api.aitc.jp/jmardb/reports/b4871712-1544-3421-a7e5-55e320fe02b7")
	puts creature_season_observation("http://api.aitc.jp/jmardb/reports/f32f302b-b026-315c-ae6d-c223c81be44f")
	puts creature_season_observation("http://api.aitc.jp/jmardb/reports/609ae627-07cf-3652-b43b-d60a884d58ca")
	puts creature_season_observation("http://api.aitc.jp/jmardb/reports/e128161d-1306-3fbe-acff-24c34678edad")
end

test_group(true, "地震情報") do
	puts earthquake_info("./test/samples/earthquark/32-35_01_01_100806_VXSE51.xml")
	#２つファイルあり
	puts earthquake_info("./test/samples/earthquark/32-35_01_03_100806_VXSE53.xml")
end

test_group(false, "津波情報") do
end

puts ""
