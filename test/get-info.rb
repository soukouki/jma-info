
# テスト側を変えないためにここでincludeしている
# 処理長すぎるから並列化したい
# aitcにいっぱいアクセスしてるのはどうなのか
def test_group execute, name, &block
	if execute
		puts "\n"+name
		Module.include(GetInfo).module_eval(&block)
	else
		print "s"
	end
end

test_group(false, "一般報") do
	puts get_info("./test/samples/general/20_01_01_100514_VPZJ50.xml")
	puts get_info("./test/samples/general/21_01_01_160628_VPCJ50.xml")
	puts get_info("./test/samples/general/22_01_01_100514_VPFJ50.xml")
	puts get_info("./test/samples/general/府県海氷予報-1.xml")
	puts get_info("./test/samples/general/全般台風情報（定型）-1.xml")
	puts get_info("./test/samples/general/府県高温注意情報-1.xml")
	puts get_info("./test/samples/general/府県潮位情報-1.xml")
	puts get_info("./test/samples/general/42_01_01_100514_VZSE40.xml")
	puts get_info("./test/samples/general/42_02_01_100831_VZVO40.xml")
end

test_group(false, "天気予報") do
	puts get_info("./test/samples/weather_forecast/府県天気予報-1.xml")
	puts get_info("./test/samples/weather_forecast/24_04_01_100806_VPFD50.xml")
end

test_group(false, "概況") do
	# 単独だしファイル作らなくていい気がする
	puts get_info("./test/samples/general_weather_conditions/府県天気概況-1.xml")
	puts get_info("./test/samples/general_weather_conditions/府県天気概況-2.xml")
end

test_group(false, "特別警報・警報・注意報") do
	test_group(false, "特別警報・警報・注意報") do
		puts get_info("./test/samples/alert/15_08_01_130412_VPWW53.xml")
		puts get_info("./test/samples/alert/15_08_02_130412_VPWW53.xml")
		puts get_info("./test/samples/alert/15_08_03_160628_VPWW53.xml")
		puts get_info("./test/samples/alert/15_08_04_160628_VPWW53.xml")
		puts get_info("./test/samples/alert/15_08_05_130412_VPWW53.xml")
		puts get_info("./test/samples/alert/15_09_01_160628_VPWW53.xml")
		puts get_info("./test/samples/alert/15_09_02_160628_VPWW53.xml")
		puts get_info("./test/samples/alert/15_09_03_130826_VPWW53.xml")
		puts get_info("./test/samples/alert/15_10_03_160628_VPWW53.xml")
		puts get_info("./test/samples/alert/15_12_01_161130_VPWW53.xml")
		puts get_info("./test/samples/alert/15_12_02_161130_VPWW53.xml")
		puts get_info("./test/samples/alert/15_12_03_161130_VPWW53.xml")
		puts get_info("./test/samples/alert/15_13_01_161226_VPWW53.xml")
		puts get_info("./test/samples/alert/15_14_01_170216_VPWW53.xml")
	end
	puts get_info("http://api.aitc.jp/jmardb/reports/318823e2-674b-3df0-b2e3-e2d1537fab37") # 複数の地域が一緒になっていることがあるため
	puts get_info("http://api.aitc.jp/jmardb/reports/bc4f48b1-3f39-3517-b4df-815fae2d5a17") # 地域のデータのバグ修正
	puts get_info("http://api.aitc.jp/jmardb/reports/ce9f85c8-76d0-35d4-a914-2f44262c38af") # 海関係の典型的な例
end

test_group(false, "季節観測・特殊気象報") do
	puts get_info("./test/samples/special_weather_report/01_01_01_091210_VGSK50.xml")
	puts get_info("./test/samples/special_weather_report/季節観測-1.xml")
	puts get_info("./test/samples/special_weather_report/季節観測-2.xml")
	puts get_info("./test/samples/special_weather_report/03_01_01_091210_VGSK60.xml")
	puts get_info("./test/samples/special_weather_report/特殊気象報-1.xml")
	puts get_info("./test/samples/special_weather_report/特殊気象報-2.xml")
	puts get_info("./test/samples/special_weather_report/特殊気象報-3.xml")
end

test_group(false, "地方海上警報") do
	puts get_info("./test/samples/local_maritime_alert/地方海上警報-1.xml")
	puts get_info("./test/samples/local_maritime_alert/地方海上警報-2.xml")
	puts get_info("./test/samples/local_maritime_alert/地方海上警報-3.xml")
	puts get_info("./test/samples/local_maritime_alert/地方海上警報-4.xml")
	puts get_info("./test/samples/local_maritime_alert/地方海上警報-5.xml")
	puts get_info("./test/samples/local_maritime_alert/地方海上警報-6.xml")
	puts get_info("./test/samples/local_maritime_alert/地方海上警報-7.xml")
end

test_group(false, "生物季節観測") do
	puts get_info("./test/samples/season_observation/生物季節観測-1.xml")
	puts get_info("./test/samples/season_observation/生物季節観測-2.xml")
	puts get_info("./test/samples/season_observation/生物季節観測-3.xml")
	puts get_info("./test/samples/season_observation/生物季節観測-4.xml")
end

test_group(false, "記録的短時間大雨情報") do
	puts get_info("./test/samples/rare_rain/18_01_01_100806_VPOA50.xml")
	puts get_info("./test/samples/rare_rain/18_02_01_111226_VPOA50.xml")
	puts get_info("./test/samples/rare_rain/18_03_01_130906_VPOA50.xml")
end

test_group(false, "地震情報") do
	test_group(false, "震度速報") do
		puts get_info("./test/samples/earthquake/32-35_01_01_100806_VXSE51.xml")
		puts get_info("./test/samples/earthquake/32-35_04_01_100831_VXSE51.xml")
		puts get_info("./test/samples/earthquake/32-35_04_02_100831_VXSE51.xml")
		puts get_info("./test/samples/earthquake/32-35_04_05_100831_VXSE51.xml")
		puts get_info("./test/samples/earthquake/32-35_07_01_100915_VXSE51.xml")
		puts get_info("./test/samples/earthquake/32-35_07_02_100915_VXSE51.xml")
		puts get_info("./test/samples/earthquake/32-35_07_03_100915_VXSE51.xml")
		puts get_info("./test/samples/earthquake/32-35_07_04_100915_VXSE51.xml")
		puts get_info("./test/samples/earthquake/32-35_07_05_100915_VXSE51.xml")
		puts get_info("./test/samples/earthquake/32-35_08_01_100915_VXSE51.xml")
		puts get_info("./test/samples/earthquake/32-35_08_02_100915_VXSE51.xml")
		puts get_info("./test/samples/earthquake/32-35_08_03_100915_VXSE51.xml")
		puts get_info("./test/samples/earthquake/32-35_08_04_100915_VXSE51.xml")
		puts get_info("./test/samples/earthquake/32-35_08_05_100915_VXSE51.xml")
	end
	test_group(false, "震源に関する情報") do
		puts get_info("./test/samples/earthquake/32-35_06_02_100915_VXSE52.xml") # 取り消し
		puts get_info("./test/samples/earthquake/32-35_01_02_100514_VXSE52.xml")
		puts get_info("./test/samples/earthquake/32-35_04_03_100831_VXSE52.xml")
		puts get_info("./test/samples/earthquake/32-35_06_01_100915_VXSE52.xml")
		puts get_info("./test/samples/earthquake/32-35_08_06_100915_VXSE52.xml")
		puts get_info("./test/samples/earthquake/33_12_01_120615_VXSE41.xml")
	end
	test_group(false, "震源・震度に関する情報") do
		puts get_info("./test/samples/earthquake/32-35_06_06_100915_VXSE53.xml") # 取り消し
		puts get_info("./test/samples/earthquake/32-35_01_03_100806_VXSE53.xml")
		puts get_info("./test/samples/earthquake/32-35_04_04_100831_VXSE53.xml")
		puts get_info("./test/samples/earthquake/32-35_04_06_100831_VXSE53.xml")
		puts get_info("./test/samples/earthquake/32-35_06_03_100915_VXSE53.xml")
		puts get_info("./test/samples/earthquake/32-35_06_04_100915_VXSE53.xml")
		puts get_info("./test/samples/earthquake/32-35_06_05_100915_VXSE53.xml")
		puts get_info("./test/samples/earthquake/32-35_07_06_100915_VXSE53.xml")
		puts get_info("./test/samples/earthquake/32-35_07_07_100915_VXSE53.xml")
		puts get_info("./test/samples/earthquake/32-35_08_07_100915_VXSE53.xml")
		puts get_info("./test/samples/earthquake/32-35_08_08_100915_VXSE53.xml")
	end
	test_group(false, "地震の活動状況等に関する情報") do
		puts get_info("./test/samples/earthquake/32-35_06_13_100915_VXSE56.xml") # 取り消し
		puts get_info("./test/samples/earthquake/32-35_06_08_100915_VXSE56.xml")
		puts get_info("./test/samples/earthquake/32-35_02_01_100514_VXSE56.xml")
		puts get_info("./test/samples/earthquake/32-35_06_07_100915_VXSE56.xml")
		puts get_info("./test/samples/earthquake/32-35_06_11_100915_VXSE56.xml")
		puts get_info("./test/samples/earthquake/32-35_06_12_100915_VXSE56.xml")
		puts get_info("./test/samples/earthquake/32-35_07_08_100915_VXSE56.xml")
	end
	test_group(false, "顕著な地震の震源要素更新のお知らせ") do
		puts get_info("./test/samples/earthquake/32-35_06_10_100915_VXSE61.xml") # 取り消し
		puts get_info("./test/samples/earthquake/32-35_03_02_100514_VXSE61.xml")
		puts get_info("./test/samples/earthquake/32-35_06_09_100915_VXSE61.xml")
		puts get_info("./test/samples/earthquake/32-35_07_09_100915_VXSE61.xml")
		puts get_info("./test/samples/earthquake/顕著な地震の震源要素更新のお知らせ-1.xml")
	end
	test_group(false, "地震回数に関する情報") do
		puts get_info("./test/samples/earthquake/32-35_03_01_100514_VXSE60.xml")
		puts get_info("./test/samples/earthquake/地震回数に関する情報-1.xml")
	end
	#puts get_info("./test/samples/earthquake/32-35_01_03_100514_VXSE53.xml") # 遠方地震
end

# 津波情報がget_infoで止められて一部実行できてない。
test_group(false, "津波情報") do
	puts get_info("./test/samples/tsunami/38-39_01_01_100831_VTSE40.xml")
	puts get_info("./test/samples/tsunami/38-39_01_02_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/38-39_01_03_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/38-39_01_04_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/38-39_01_05_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/38-39_01_06_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/38-39_01_07_100831_VTSE40.xml")
	puts get_info("./test/samples/tsunami/32-39_05_01_100831_VXSE53.xml")
	puts get_info("./test/samples/tsunami/32-39_05_02_100831_VXSE53.xml")
	puts get_info("./test/samples/tsunami/32-39_05_03_100831_VXSE56.xml")
	puts get_info("./test/samples/tsunami/32-39_05_04_100831_VXSE53.xml")
	puts get_info("./test/samples/tsunami/32-39_05_05_100831_VXSE53.xml")
	puts get_info("./test/samples/tsunami/32-39_05_06_100831_VXSE53.xml")
	puts get_info("./test/samples/tsunami/32-39_05_07_100831_VXSE53.xml")
	puts get_info("./test/samples/tsunami/32-39_05_08_100831_VXSE53.xml")
	puts get_info("./test/samples/tsunami/32-39_05_09_100831_VXSE56.xml")
	puts get_info("./test/samples/tsunami/32-39_05_10_100831_VTSE40.xml")
	puts get_info("./test/samples/tsunami/32-39_05_11_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_12_100831_VXSE53.xml")
	puts get_info("./test/samples/tsunami/32-39_05_12_100915_VXSE53.xml")
	puts get_info("./test/samples/tsunami/32-39_05_13_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_14_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_15_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_16_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_17_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_18_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_19_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_20_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_21_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_22_100831_VXSE56.xml")
	puts get_info("./test/samples/tsunami/32-39_05_23_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_24_100831_VTSE40.xml")
	puts get_info("./test/samples/tsunami/32-39_05_25_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_26_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_27_100831_VTSE40.xml")
	puts get_info("./test/samples/tsunami/32-39_05_28_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_29_100831_VXSE56.xml")
	puts get_info("./test/samples/tsunami/32-39_05_30_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_31_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_32_100831_VTSE40.xml")
	puts get_info("./test/samples/tsunami/32-39_05_33_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_34_100831_VTSE40.xml")
	puts get_info("./test/samples/tsunami/32-39_05_35_100831_VTSE40.xml")
	puts get_info("./test/samples/tsunami/32-39_05_36_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_05_37_100831_VTSE40.xml")
	puts get_info("./test/samples/tsunami/32-39_05_38_100831_VXSE56.xml")
	puts get_info("./test/samples/tsunami/32-39_05_39_100831_VTSE40.xml")
	puts get_info("./test/samples/tsunami/32-39_05_40_100831_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_11_01_120615_VXSE51.xml")
	puts get_info("./test/samples/tsunami/32-39_11_02_120615_VTSE40.xml")
	puts get_info("./test/samples/tsunami/32-39_11_03_120615_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_11_05_120615_VXSE53.xml")
	puts get_info("./test/samples/tsunami/32-39_11_06_120615_VTSE40.xml")
	puts get_info("./test/samples/tsunami/32-39_11_08_120615_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_11_09_120615_VTSE40.xml")
	puts get_info("./test/samples/tsunami/32-39_11_10_120615_VTSE50.xml")
	puts get_info("./test/samples/tsunami/32-39_11_11_120615_VTSE40.xml")
	puts get_info("./test/samples/tsunami/32-39_11_13_120615_VTSE40.xml")
	# なんで沖合の津波観測だけ別になってるんですか！！
	puts get_info("./test/samples/tsunami/61_11_01_120615_VTSE52.xml")
	puts get_info("./test/samples/tsunami/61_11_02_120615_VTSE52.xml")
	puts get_info("./test/samples/tsunami/61_11_03_120615_VTSE52.xml")
end

puts ""
