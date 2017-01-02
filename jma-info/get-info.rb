
require "open-uri"

require "rexml/document"

def get_doc uri
	REXML::Document.new(open(uri))
end

def cleanly_text text
	text
		.gsub(/\u3000|\n(?!\n)/){""} # 全角スペースと単独の改行を消す
		.gsub(/\n{2,}/){"\n"} # 連続の改行を一つの改行にする
		.gsub(/^/){"\t"} # 行のはじめにタブを付ける
end

def delete_parentheses str
	str.gsub(/(.+)（.+）/){$1}
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
	doc.elements["Report/Head/Headline/Text"].text.gsub(/。([^\n])/){"。\n\t#{$1}"}+
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
		average_year_diff = add_info.elements["DeviationFromNormal"].text.to_i
		item.elements["Kind/Name"].text+
		((add_info.elements["Text"].nil?)? "" : " "+delete_parentheses(add_info.elements["Text"].text))+"\n\t"+
		"平年より#{average_year_diff.abs}日"+((average_year_diff.positive?)? "遅い" : "早い")
	when "特殊気象報（風）"
		"風"+"\n\t"+format_special_weather_report_wind(item)
	when "特殊気象報（気圧）"
		"気圧"+"\n\t"+item.elements["Kind/Property/PressurePart/Temporary/jmx_eb:Pressure"].attributes["description"]
	when "特殊気象報（各種現象）"
		item.elements["Kind/Name"].text+"\n\t"+
		delete_parentheses(add_info.elements["Text"].text).tr('０-９．　', '0-9. ')
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

def get_info(uri_and_title)
	case uri_and_title.title
	when # 一般報
		/^全般台風情報/, "全般気象情報", "地方気象情報", "府県気象情報", "天気概況",
		"全般週間天気予報", "地方週間天気予報", "スモッグ気象情報", "全般スモッグ気象情報",
		"全般潮位情報", "地方潮位情報", "府県潮位情報", "府県海氷予報", "地方高温注意情報", "府県高温注意情報 "
		uri_and_title.title+" : "+get_general_report(uri_and_title.uri)
	when "府県天気概況"
		uri_and_title.title+" : "+get_general_weather_conditions(uri_and_title.uri)
	when "気象警報・注意報" # 無視
	when "気象特別警報・警報・注意報"
		uri_and_title.title+" : "+get_alerm(uri_and_title.uri)
	when "季節観測", "特殊気象報"
		uri_and_title.title+" : "+get_special_weather_report(uri_and_title.uri)
	else
		uri_and_title.title
	end
end