
require "open-uri"
require "time"

require "rexml/document"

module GetInfo extend self
	def get_info(uri_and_title)
		title = uri_and_title.title
		uri = uri_and_title.uri
		case title
		when # 一般報
			"全般台風情報", "全般台風情報（定型）", "全般台風情報（詳細）", "発達する熱帯低気圧に関する情報",
			"全般気象情報", "地方気象情報", "府県気象情報", "天気概況", "全般週間天気予報", "地方週間天気予報",
			"スモッグ気象情報", "全般スモッグ気象情報", "全般潮位情報", "地方潮位情報", "府県潮位情報", "府県海氷予報",
			"地方高温注意情報", "府県高温注意情報", "火山に関するお知らせ", "地震・津波に関するお知らせ"
			title+" : "+get_general_report(uri)
		when "府県天気概況"
			title+" : "+get_general_weather_conditions(uri)
		when "気象警報・注意報", "気象特別警報報知" # 無視
		when "気象特別警報・警報・注意報"
			title+" : "+get_alerm(uri)
		when "季節観測", "特殊気象報"
			title+" : "+get_special_weather_report(uri)
		when "地方海上警報（Ｈ２８）" # 無視
		when "地方海上警報"
			title+" : "+get_local_maritime_alert(uri)
		when "生物季節観測"
			title+" : "+creature_season_observation(uri)
		when # 地震、津波
			"震度速報", "震源に関する情報", "震源・震度に関する情報",
			"地震の活動状況に関する情報", "地震回数に関する情報",
			"津波情報a", "津波警報・注意報・予報a", "沖合の津波観測に関する情報"
			title+" : "+earthquake_info(uri)
		else
			title
		end
	end
	
	private
	
	def get_doc uri
		REXML::Document.new(open(uri))
	end
	
	# 文章を綺麗にする
	def cleanly_text text
		cleanly_str(text)
			.gsub(/\n(?!\n)/){""} # 単独の改行を消す
			.gsub(/\n{2,}/){"\n"} # 連続の改行を一つの改行にする
			.gsub("  "){" "} # 連続した空白を一つにまとめる
			.gsub(/^/){"\t"} # 行のはじめにタブを付ける
			.gsub(/\n+\Z/){""} # 文章の最後の改行を削除
	end
	# 数字や、文字を置き換える
	def cleanly_str text
		text.tr('０-９Ａ-Ｚａ-ｚ．＊－（）　', '0-9A-Za-z.*\-() ') # 全角を半角に
			.gsub(/ (\d)/){$1} # 数字の前の空白を削除
	end
	
	def delete_parentheses str
		str.gsub(/(.+)（.+）/){$1}
	end
	
	def days_diff days
		if days=="nil"
			"データなし"
		elsif days.to_i.positive?
			days+"日遅い"
		elsif days.to_i.negative?
			days.to_i.abs.to_s+"日早い"
		else
			"同日"
		end
	end
	
	def last_year_and_normal_year_text xmlitem
		xnil = Struct.new(:a){def text;"";end}.new
		
		normal = (xmlitem.elements["DeviationFromNormal"]||xnil.new).text
		lastyear = (xmlitem.elements["DeviationFromLastYear"]||xnil.new).text
		"昨年比"+days_diff(lastyear)+", 平年比"+days_diff(normal)
	end
	
	def get_general_report uri
		doc=get_doc(uri)
		head = doc.elements["Report/Head"]
		body = doc.elements["Report/Body"]
		cleanly_str(head.elements["Title"].text)+"\n"+
		((head.elements["Headline/Text[.!='']"])? cleanly_text(head.elements["Headline/Text"].text+"\n") : "")+
		cleanly_text(body.elements["(Comment/Text)|(Text)"].text.gsub("。"){"。\n"})+"\n"
	end
	
	def get_general_weather_conditions uri
		doc = get_doc(uri)
		body = doc.elements["Report/Body"]
		body.elements["TargetArea/Name"].text+"\n"+
		cleanly_text(body.elements["Report/Body/Comment/Text"].text)+"\n"
	end
	
	def get_alerm uri
		doc = get_doc(uri)
		doc.elements[
			"Report/Head/Headline/Information[@type=\"気象警報・注意報（府県予報区等）\"]/Item/Areas/Area/Name"].text+"\n\t"+
		doc.elements["Report/Head/Headline/Text"].text.gsub(/。(?=\n)/){"。\n\t"}+
		alerm_info(doc)
	end
	
	def alerm_info doc
		if doc.elements["Report/Head/Headline/Information[@type=\"気象警報・注意報（警報注意報種別毎）\"]"]
			"\n\t"+format_alerm_info(doc)
		else # 解除時
			""
		end
	end
	
	def format_alerm_info doc
		doc.elements["Report/Head/Headline/Information[@type=\"気象警報・注意報（警報注意報種別毎）\"]"]
			.select{|x|x!="\n"}
			.map do |a|
				a.elements["Kind/Name"].text+"が"+
				a.elements["Areas"].select{|x|x!="\n"}.map{|b|b.elements["Name"].text}.join("、")+"に"
			end
			.join("、")+"出ています。"
	end
	
	def get_special_weather_report uri
		doc = get_doc(uri)
		item = doc.elements["Report/Body/MeteorologicalInfos/MeteorologicalInfo/Item"]
		add_info = doc.elements["Report/Body/AdditionalInfo/ObservationAddition"]
		item.elements["Station/Name"].text+" "+
		case doc.elements["Report/Head/Title"].text
		when "季節観測"
			item_text = ((add_info.elements["Text"].nil?)? "" : delete_parentheses(add_info.elements["Text"].text))
			item.elements["Kind/Name"].text+" "+item_text+"\n\t"+last_year_and_normal_year_text(add_info)
		when "特殊気象報（風）"
			"風"+"\n\t"+format_special_weather_report_wind(item)
		when "特殊気象報（各種現象）"
			item.elements["Kind/Name"].text+"\n"+
			cleanly_text(delete_parentheses(add_info.elements["Text"].text.tr("　", " ")))+"\n"
		end
	end
	
	def format_special_weather_report_wind item
		item.elements["Kind/Property/WindPart"]
			.select{|a|a.kind_of?(REXML::Element)}
			.map do |w|
				w.elements["jmx_eb:WindDegree"].attributes["description"]+" "
				w.elements["jmx_eb:WindSpeed"].attributes["description"]
			end.join(", ")
	end
	
	def get_local_maritime_alert uri
		doc = get_doc(uri)
		item = doc.elements["Report/Body/Warning"].select{|a|a.kind_of?(REXML::Element)}
		doc.elements["Report/Body/MeteorologicalInfos/MeteorologicalInfo/Item/Area/Name"].text+
		item.map do |it|
			sentence = it.elements["Kind/Property/*/SubArea/Sentence"]
			((sentence.nil?)? "" : "\n"+cleanly_text(sentence.text).gsub(" "){"、"})
		end.join("")+"\n\t"+
		item
			.map{|a|a.elements["Kind/Name"].text}.uniq
			.map do |k|
				k+"が"+item
					.select{|a|a.elements["Kind/Name"].text==k}.
					map{|a|a.elements["Area/Name"].text}.join(" ")+"に"
			end.join("、")+"出ています。"
	end
	
	def creature_season_observation uri
		doc = get_doc(uri)
		item = doc.elements["Report/Body/MeteorologicalInfos/MeteorologicalInfo/Item"]
		pos = item.elements["Station/Location"].text
		data = item.elements["Kind/Name"].text+
			"("+item.elements["Kind/ClassName"].text+", "+item.elements["Kind/Condition"].text+")"
		daystext = last_year_and_normal_year_text(doc.elements["Report/Body/AdditionalInfo/ObservationAddition"])
		
		pos+"\n\t"+data+"\n\t"+daystext
	end
	
	# 一部の地震情報と津波情報は、違うタイトルで同じことをするものがあり、分けれないため、この関数内で地震情報と津波情報を処理する
	# それ以外のやつも一緒になってるのはCommentsとかだったりノリ
	# 警報のほうでも予想の方でも時刻つなげてるのはちょっと冗長かも知れない
	def earthquake_info uri
		doc = get_doc(uri)
		heading = ((doc.elements["Report/Head/Headline/Text/text()"])?
			(cleanly_str(doc.elements["Report/Head/Headline/Text"].text).gsub("\n"){""}) : "")
		text = doc.elements.collect("Report/Body/*") do |info|
			case info.name # whenのコメントはたぶん間違ってるとこが少なくとも1箇所あるきがするので信じすぎないように
			when "Earthquake" # 震源に関する情報 + 震源・震度に関する情報 + 津波警報・注意報・予報a + 津波情報a + 沖合の津波観測に関する情報
				earthquake_info_earthquake_paet(info)
			when "Intensity" # 震度速報 + 震源・震度に関する情報
				earthquake_info_intensity_part(info, info.elements["count(Observation/CodeDefine/Type)"]==4)
			when "Tsunami" # 津波警報・注意報・予報a + 津波情報a + 沖合の津波観測に関する情報
				earthquake_info_tsunami_part(info)
			when "Naming" # 地震の活動状況に関する情報
				"\t"+info.text+"\n"
			when "EarthquakeCount" # 地震回数に関する情報
				earthquake_info_count_part(info)
			when "NextAdvisory" # 地震回数に関する情報
				cleanly_text(info.text)+"\n"
			when "Text" # すべて
				cleanly_text(info.text)+"\n"
			when "Comments" # すべて
				earthquake_info_comment_part(info)
			end
		end.join
		heading+"\n"+text
	end
	
	def earthquake_info_earthquake_paet info
		area = info.elements["Hypocenter/Area"]
		"\t震源地:"+area.elements["Name/text()"].value+
		((area.elements["DetailedName"])? "("+area.elements["DetailedName/text()"].value+")" : "")+
		((area.elements["NameFromMark"])? "("+cleanly_str(area.elements["NameFromMark/text()"].value)+")" : "")+"\n\t"+
		"\t"+cleanly_str(area.elements["jmx_eb:Coordinate/@description"].value)+"\n\t"+
		"マグニチュード:"+cleanly_str(info.elements["jmx_eb:Magnitude/@description"].value.sub("Ｍ"){})+"\n"+
		((info.elements["Hypocenter/Source"])? "\t情報元:"+cleanly_str(info.elements["Hypocenter/Source/text()"].value)+"\n" :  "")
	end
	
	def earthquake_info_intensity_part info, is_detail_info
		"\t最大震度:"+get_maxint(info.elements["Observation"])+"\n\t"+intensity_pref_xml_to_s(info, is_detail_info)
	end
	def intensity_pref_xml_to_s info, is_detail_info
		info.elements
			.collect("Observation/Pref"){|pref|
				get_name(pref)+((is_detail_info)? ":"+get_maxint(pref)+"\n\t" : "、")+
					intensity_area_xml_to_s(pref, is_detail_info)}
			.join("\n\t")+"\n"
	end
	def intensity_area_xml_to_s pref, is_detail_info
		# こっから先(city IS)は震源・震度に関する情報のときだけ
		pref.elements
			.collect("Area"){|area|
				(!is_detail_info)? get_name_and_maxint(area) :
					(get_name(area)+":"+get_maxint(area)+"\n\t\t"+intensity_city_xml_to_s(area))}
			.join((is_detail_info)? "\n\t" : "、")
	end
	def intensity_city_xml_to_s area
		area.elements
			.collect("City"){|city|get_name(city)+"、"+intensity_station_xml_to_s(city)}
			.join("\n\t\t")
	end
	def intensity_station_xml_to_s city
		city.elements
			.collect("IntensityStation"){|is|cleanly_str(get_name(is))+":"+sint_to_s(is.elements["Int/text()"].value)}
			.join("、")
	end
	def sint_to_s si
		# 震度のgsubは、震度5弱以上未入電のときの最初の震度を消すため。
		cleanly_str("震度"+si.gsub("震度"){""}.gsub("+"){"強"}.gsub("-"){"弱"})
	end
	def get_maxint doc
		sint_to_s(doc.elements["MaxInt/text()"].to_s)
	end
	def get_name doc
		doc.elements["Name/text()"].value
	end
	def get_name_and_maxint doc
		get_name(doc)+":"+get_maxint(doc)
	end
	
	def earthquake_info_tsunami_part info
		"\t"+info.elements.collect("*") do |tinfo|
			case tinfo.name
			when "Observation"
				earthquake_info_tsunami_observation_part(tinfo)
			when "Forecast"
				earthquake_info_tsunami_forecast_part(tinfo)
			when "Estimation"
				tinfo.elements.collect("Item"){|item|item.elements["Area/Name"].text+"、"+max_height_xml_to_s(item)}.join("\n\t")
			end
		end.join("\n\t")+"\n"
	end
	def earthquake_info_tsunami_observation_part tinfo
		is_offing = tinfo.elements["Item/Area/Name/text()"].nil?
		tinfo.elements.collect("Item"){|item|
			((is_offing)? "沖合での津波観測" : item.elements["Area/Name"].text)+"\n\t\t"+
			item.elements.collect("Station"){|sta|
				sta.elements["Name"].text+
				max_height_xml_to_s(sta)+
				((is_offing)? "("+cleanly_str(sta.elements["Sensor"].text)+")" : "")
			}.join("\n\t\t")}.join("\n\t")
	end
	def earthquake_info_tsunami_forecast_part tinfo
		tinfo.elements.collect("Item") do |item|
			item.elements["Area/Name"].text+"、"+item.elements["Category/Kind/Name"].text+
			first_height_to_s(item, ->(t){times_to_dhm_s(t)})+
			((item.elements["MaxHeight/jmx_eb:TsunamiHeight/@description!=\"\""])? # ""になっている場合がある
				("、高さ:"+cleanly_str(item.elements["MaxHeight/jmx_eb:TsunamiHeight/@description"].value)) : "")+
			((!item.elements["Station"])? "" : "\n\t\t"+item.elements.collect("Station"){|sta|
					sta.elements["Name"].text+first_height_to_s(sta, ->(t){times_to_hm_s(t)})
				}.join("\n\t\t"))
		end.join("\n\t")
	end
	def first_height_to_s fh, time_to_s
		((!fh.elements["FirstHeight"])? "" :
			((fh.elements["FirstHeight/ArrivalTime"])?
				"、到達予想:"+times_to_dhm_s(fh.elements["FirstHeight/ArrivalTime"].text) : "")+
			((fh.elements["FirstHeight/Condition"])? "、"+fh.elements["FirstHeight/Condition"].text : ""))
	end
	def times_to_hm_s times
		Time.parse(times).strftime("%H時%m分")
	end
	def times_to_dhm_s times
		Time.parse(times).strftime("%d日%H時%m分")
	end
	def max_height_xml_to_s doc
		((doc.elements["MaxHeight/DateTime"])? "、"+times_to_hm_s(doc.elements["MaxHeight/DateTime"].text) : "")+
		((doc.elements["MaxHeight/Condition"])? "、"+doc.elements["MaxHeight/Condition"].text.gsub(/。$/){""} : "")+
		((doc.elements["MaxHeight/jmx_eb:TsunamiHeight"])?
			"、"+cleanly_str(doc.elements["MaxHeight/jmx_eb:TsunamiHeight/@description"].value) : "")+
		((doc.elements["MaxHeight/jmx_eb:TsunamiHeight/@condition"])?
			"、"+doc.elements["MaxHeight/jmx_eb:TsunamiHeight/@condition"].value : "")
	end
	
	def earthquake_info_count_part info
		"\t"+info
			.elements.collect("Item"){|item|
				s = Time.parse(item.elements["StartTime"].text)
				e = Time.parse(item.elements["EndTime"].text)
				time_to_counts_s(s)+"から"+
				time_to_counts_s(e)+"までの"+
				time_diff_to_count_s(e-s)+"で、"+
				((item.elements["Number"].text!="-1")? (num=true; "回数:"+item.elements["Number"].text+"回") : "")+
				((item.elements["FeltNumber"].text!="-1")? ((num)? "、" : "")+"有感:"+item.elements["FeltNumber"].text+"回" : "")}
			.join("\n\t")+"\n"
	end
	def time_to_counts_s time
		time.strftime("%m月%d日%H時")
	end
	# 日~時まで
	def time_diff_to_count_s diff
		((diff>=(60*60*24))? (day=true; (diff.to_i/(60*60*24)).to_s+"日") : "")+
		((diff.to_i % (60*60*24)>=1)? (((day)? "と" : "")+((diff.to_i % (60*60*24))/(60*60)).to_s+"時間") : "")
	end
	
	def earthquake_info_comment_part info
		info
			.elements
			.collect("*/Text||FreeFormComment"){|c|cleanly_text(c.text.gsub(/^\s+|\s+$/){""})}
			.select{|a|a!=nil && !(a.match(/^[ \t\n]+$/))}
			.join("\n")+"\n"
	end
end
