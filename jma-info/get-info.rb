
require "open-uri"

require "rexml/document"

module GetInfo
	def self.get_info(uri_and_title)
		title = uri_and_title.title
		uri = uri_and_title.uri
		case title
		when # 一般報
			/^全般台風情報/, "全般気象情報", "地方気象情報", "府県気象情報", "天気概況",
			"全般週間天気予報", "地方週間天気予報", "スモッグ気象情報", "全般スモッグ気象情報",
			"全般潮位情報", "地方潮位情報", "府県潮位情報", "府県海氷予報", "地方高温注意情報", "府県高温注意情報 "
			title+" : "+get_general_report(uri)
		when "府県天気概況"
			title+" : "+get_general_weather_conditions(uri)
		when "気象警報・注意報" # 無視
		when "気象特別警報・警報・注意報"
			title+" : "+get_alerm(uri)
		when "季節観測", "特殊気象報"
			title+" : "+get_special_weather_report(uri)
		when "地方海上警報"
			title+" : "+get_local_maritime_alert(uri)
		when "生物季節観測"
			title+" : "+creature_season_observation(uri)
		else
			title
		end
	end
	
	private
	
	def get_doc uri
		REXML::Document.new(open(uri))
	end
	
	def cleanly_text text, nonetab=false
		text
			.tr('０-９．（）', '0-9.()') # 全角を半角に
			.gsub(/\u3000|\n(?!\n)/){""} # 全角スペースと単独の改行を消す
			.gsub(/\n{2,}/){"\n"} # 連続の改行を一つの改行にする
			.gsub("  "){" "} # 連続した空白を一つにまとめる
			.gsub(/^/){(nonetab)? "" : "\t"} # 行のはじめにタブを付ける
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
		doc.elements["Report/Head/Title"].text+"\n"+
		cleanly_text(doc.elements["Report/Body/Comment/Text"].text.gsub("。"){"。\n\n"})
	end
	
	def get_general_weather_conditions uri
		doc = get_doc(uri)
		doc.elements["Report/Body/TargetArea/Name"].text+"\n"+
		cleanly_text(doc.elements["Report/Body/Comment/Text"].text)
	end
	
	def get_alerm uri
		doc = get_doc(uri)
		doc.elements[
			"Report/Head/Headline/Information[@type=\"気象警報・注意報（府県予報区等）\"]"+
			"/Item/Areas/Area/Name"].text+"\n\t"+
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
				a.elements["Areas"].select{|x|x!="\n"}.map{|b|b.elements["Name"].text}.join(" ")+"に"
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
			cleanly_text(delete_parentheses(add_info.elements["Text"].text.tr("　", " ")))
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
	
	# タイトルで分けれないため、この関数内で地震情報と津波情報を処理する
	# メモ、津波関連のタイトルのあれは津波で検索するほうが良さそう。
	def earthquake_info uri
		doc = get_doc(uri)
		heading = cleanly_text(doc.elements["Report/Head/Headline/Text"].text, nonetab=true)
		text = doc
			.elements
			.collect("Report/Body/*") do |info|
				case info.name
				when "Intensity"
					# 震度速報の時false 震源震度に関する情報の時true
					is_detail_info = info.elements["count(Observation/CodeDefine/Type)"]==4
					sint_to_s = ->(si){"震度"+si.gsub("+"){"強"}.gsub("-"){"弱"}}
					maxint = ->(doc){":"+sint_to_s.call(doc.elements["MaxInt/text()"].to_s)}
					name = ->(doc){doc.elements["Name/text()"].value}
					name_and_maxint = ->(doc){name.call(doc)+maxint.call(doc)}
					"\t全体"+maxint.call(info.elements["Observation"])+"\n\t"+
					info.elements
						.collect("Observation/Pref"){|pref|
							name.call(pref)+((is_detail_info)? "\n\t" : "、")+
							pref.elements
								.collect("Area"){|area|
									((!is_detail_info)? name_and_maxint.call(area) :
										(name.call(area)+"\n\t\t"+
											area.elements
												.collect("City"){|city|
													name.call(city)+" "+
													city.elements
														.collect("IntensityStation"){|is|
															name.call(is)+":"+sint_to_s.call(is.elements["Int/text()"].to_s)}
														.join(" ")}
												.join("\n\t\t")))}
								.join((is_detail_info)? "\n\t" : "、")}
						.join("\n\t")+"\n"
				when "Comments"
					"\t"+
					info.elements
						.collect("*/Text"){|c|c.text}
						.join("\n\t")
				end
			end.join
		heading+"\n"+text
	end
	
end
