
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

def alerm_info doc
	info_type = "[@type=\"気象警報・注意報（警報注意報種別毎）\"]"
	if doc.elements["Report/Head/Headline/Information#{info_type}"]
		"\n\t"+doc.elements["Report/Head/Headline/Information#{info_type}"]
			.select{|x|x!="\n"}
			.map do |a|
				a.elements["Kind/Name"].text+"が"+
				a.elements["Areas"].select{|x|x!="\n"}.map{|b|b.elements["Name"].text}.join(" ")+"に"
			end
			.join("、")+"出ています。"
	else # 解除時
		""
	end
end

def get_alerm uri
	doc = get_doc(uri)
	info_type = "[@type=\"気象警報・注意報（府県予報区等）\"]"
	doc.elements["Report/Head/Headline/Information#{info_type}/Item/Areas/Area/Name"].text+"\n\t"+
	doc.elements["Report/Head/Headline/Text"].text.gsub(/。[^\n]/){"。\n\t"}+
	alerm_info(doc)
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
	else
		uri_and_title.title
	end
end
