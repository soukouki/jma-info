﻿

module GetInfo
	module_function
	
	AreaNameAndID = Struct.new(:name, :id)
	
	def get_info(uri)
		doc = get_doc(uri)
		title = doc.elements["Report/Control/Title"].text
		repo_title = report_title(doc)
		clean_string(case title
			when # 一般報
				"全般台風情報", "全般台風情報（定型）", "全般台風情報（詳細）", "発達する熱帯低気圧に関する情報",
				"全般気象情報", "地方気象情報", "府県気象情報", "全般週間天気予報", "地方週間天気予報",
				"スモッグ気象情報", "全般スモッグ気象情報", "全般潮位情報", "地方潮位情報", "府県潮位情報", "府県海氷予報",
				"地方高温注意情報", "府県高温注意情報", "火山に関するお知らせ", "地震・津波に関するお知らせ"
				get_general_report(doc) # 内部でrepo_titleの処理を行う
			when "府県天気予報"
				repo_title+" : "+weather_forecast(doc)
			when "府県天気概況"
				repo_title+" : "+get_general_weather_conditions(doc)
			when "気象警報・注意報", "気象特別警報報知", "気象警報・注意報（Ｈ２７）" # 無視
			when "気象特別警報・警報・注意報"
				repo_title+" : "+alert_info(doc)+"\n"
			when "季節観測", "特殊気象報"
				repo_title+get_special_weather_report(doc)+"\n"
			when "地方海上警報（Ｈ２８）" # 無視
			when "地方海上警報"
				repo_title+" : "+local_maritime_alert_info(doc)+"\n"
			when "生物季節観測"
				repo_title+" : "+creature_season_observation(doc)+"\n"
			when # 地震、津波
				"震度速報", "震源に関する情報", "震源・震度に関する情報",
				"地震の活動状況等に関する情報", "地震回数に関する情報", "顕著な地震の震源要素更新のお知らせ",
				"津波情報a", "津波警報・注意報・予報a", "沖合の津波観測に関する情報"
				repo_title+earthquake_info(doc)
			when "記録的短時間大雨情報"
				repo_title+" : "+rare_rain(doc)
			else
				repo_title+"\n"
			end || ""
		)
	end
	
	# 以下privateまで、分類分けしたEarthquakeInfoなどから呼ばれる可能性があるもの。
	
	# 文章を綺麗にする
	# TODO 表のようになっている部分の処理を考える
	def clean_text text
		clean_string(text)
			.gsub(/\n(?!\n)/){""} # 単独の改行を消す
			.gsub(/\n{2,}/){"\n"} # 連続の改行を一つの改行にする
			.gsub(/  /){" "} # 連続した空白を一つにまとめる
			.gsub(/。(?!$)/){"。\n"} # `。`の後に改行をつける
			.gsub(/^ +/){""} # 行の始めの連続したスペースを消す
			.gsub(/\n+\Z/){""} # 文章の最後の改行を削除
	end
	# 文章を綺麗にする
	# その際に行の初めにタブをつける
	def clean_text_with_tabs text
		clean_text(text)
			.gsub(/^/){"\t"} # 行のはじめにタブを付ける
	end
	# 数字や、文字を置き換える
	def clean_string text
		text.tr('０-９Ａ-Ｚａ-ｚ．＊－（）　', '0-9A-Za-z.*\-() ') # 全角を半角に
	end
	
	def delete_parentheses str
		str.gsub(/(.+)（.+）/){$1}
	end
	
	def day_diff day
		if day=="nil"
			"データなし"
		elsif day.to_i.positive?
			day+"日遅い"
		elsif day.to_i.negative?
			day.to_i.abs.to_s+"日早い"
		else
			"同日"
		end
	end
	
	def time_to_hm_s time
		time.strftime("%H時%m分")
	end
	def time_to_dhm_s time
		time.strftime("%d日%H時%M分")
	end
	def time_to_mdh_s time
		time.strftime("%m月%d日%H時")
	end
	def time_to_ymdhms_s time
		time.strftime("%Y年%m月%d日%H時%M分%S秒")
	end
	# 日~時まで
	def time_diff_to_count_s diff
		((diff>=(60*60*24))? (datetime=true; (diff.to_i/(60*60*24)).to_s+"日") : "")+
		((diff.to_i % (60*60*24)>=1)? (((datetime)? "と" : "")+((diff.to_i % (60*60*24))/(60*60)).to_s+"時間") : "")
	end
	
	def last_year_and_normal_year_text xmlitem
		xnil = Struct.new(:a){def text;"";end}
		
		normal = (xmlitem.elements["DeviationFromNormal"]||xnil.new).text
		lastyear = (xmlitem.elements["DeviationFromLastYear"]||xnil.new).text
		"昨年比"+day_diff(lastyear)+", 平年比"+day_diff(normal)
	end
	
	def get_doc uri, try_count=0
		begin
			text = open(uri)
		rescue
			if try_count > 10
				raise "GetInfo#get_docでのエラー #{uri} へのアクセスを11回失敗しました。インターネット環境を確認してください。"
			else
				sleep(10) # 長めのsleepで1分以内に同じようなエラーが出ないように
				get_doc(uri, try_count+1)
			end
		end
		REXML::Document.new(text)
	end
	
	def report_title doc
		title = doc.elements["Report/Control/Title"].text
		status = doc.elements["Report/Control/Status"].text
		info_type = doc.elements["Report/Head/InfoType"].text
		target_time = Time.parse(doc.elements["Report/Control/DateTime"].text).localtime("+09:00")
		"#{time_to_ymdhms_s(target_time)} #{info_type} #{title}#{((status!="通常")? " **#{status}**" : "")}"
	end
	
	def get_general_report doc
		head = doc.elements["Report/Head"]
		body = doc.elements["Report/Body"]
		repo_title = report_title(doc)
		
		control_title = doc.elements["Report/Control/Title"].text
		head_title = clean_text(head.elements["Title"].text)
		header = (
			if control_title == head_title
				# 火山に関するお知らせ
				repo_title
			elsif control_title[0..1]=="府県" && control_title[2..-1]==head_title[-control_title.length+2..-1] && !head_title.include?("に関する")
				# 府県海氷予報 : 宗谷地方海氷予報 => 府県海氷予報 : 宗谷地方
				repo_title+" : "+head_title[0..head_title.length-control_title.length+1]
			else
				repo_title+" : "+head_title
			end
		)
		
		header+"\n"+
		((head.elements["Headline/Text[.!='']"])? clean_text_with_tabs(head.elements["Headline/Text"].text)+"\n" : "")+
		clean_text_with_tabs(body.elements["(Comment/Text)|(Text)"].text.gsub("。"){"。\n"})+"\n"
	end
	
	def weather_forecast doc
		WeatherForecast.weather_forecast(doc)
	end
	module WeatherForecast
		module_function
		extend GetInfo
		
		def weather_forecast doc
			head = doc.elements["Report/Head"]
			body = doc.elements["Report/Body"]
			
			info = body
				.elements
				.each("MeteorologicalInfos/TimeSeriesInfo"){} # 独自予報は予報の中にテキストで時刻が入ってたりして、統一できないので捨てます
				.map do |time_series_info|
					time_define = time_define(time_series_info)
					
					time_series_info
						.elements
						.collect("Item") do |item|
							item_ele = item.elements
							area_doc_ele = (item_ele["Area"] || item_ele["Station"]).elements
							area = AreaNameAndID.new(area_doc_ele["Name"].text, area_doc_ele["Code"].text.to_i)
							item
								.elements
								.collect("Kind/Property") do |kind|
									kind_info(kind:kind, area:area, time_define:time_define)
								end
						end
				end
				.flatten
				.group_by{|hash|hash[:td].day}
				.map do |day, hashes_by_day|
					t = Time.parse(head.elements["TargetDateTime"].text)
					d = 60*60*24
					date_nicknames = {
						(t-1*d).day => "昨日",
						(t+0*d).day => "今日",
						(t+1*d).day => "明日",
						(t+2*d).day => "あさって",
					}
					"\t#{day}日#{(date_nicknames[day].nil?)? "" : "(#{date_nicknames[day]})"}\n"+
					hashes_by_day
						.group_by{|hash|hash[:area]}
						.map do |area, hashes_by_area|
							"\t\t#{area.name}\n"+
							hashes_by_area
								.group_by{|hash|hash[:range]}
								.sort_by{|r,hs|r||[]}
								.map do |range, hashes_by_range|
									if range.nil?
										hashes_by_range
											.map{|h|"\t\t\t#{h[:text]}"}
											.join("\n")
									else
										"\t\t\t#{range[0].to_s.rjust(2)}-#{range[1].to_s.rjust(2)} : "+
										hashes_by_range
											.map{|h|"#{h[:text]}"}
											.join("、")
									end
								end
								.join("\n")
						end
						.join("\n")
				end
				.join("\n")
			
			head.elements["Title"].text.gsub("府県天気予報"){""}+"\n"+info
		end
		
		def kind_info kind:, area:, time_define:
			type = clean_string(kind.elements["Type"].text)
			case type
			when "天気", "風", "波"
				kind
					.elements
					.collect("DetailForecast/*") do |part|
						{
							area: area,
							td: time_define_by_part(time_define, part),
							text: "#{type}\n\t\t\t\t#{part.elements["Sentence"].text}",
						}
					end
			when "降水確率"
				kind
					.elements
					.collect("ProbabilityOfPrecipitationPart/jmx_eb:ProbabilityOfPrecipitation") do |part|
						td = time_define_by_part(time_define, part)
						{
							area: area,
							td: td,
							range: [td.hour, td.hour+6],
							text: "降水確率 #{part.text}%(#{part.attribute("condition")})",
						}
					end
			when "日中の最高気温", "最高気温", "朝の最低気温"
				t = kind.elements["TemperaturePart/jmx_eb:Temperature"]
				{
					area: area,
					td: time_define_by_part(time_define, t),
					text: "#{type} #{t.text}度"
				}
			when "3時間内卓越天気"
				kind
					.elements
					.collect("WeatherPart/jmx_eb:Weather") do |part|
						td = time_define_by_part(time_define, part)
						{
							area: area,
							td: td,
							range: [td.hour, td.hour+3],
							text: part.text,
						}
					end
			when "3時間内代表風"
				time_define
					.map do |refid, td|
						direction = kind.elements["WindDirectionPart/jmx_eb:WindDirection[@refID='#{refid}']"]
						level = kind.elements["WindSpeedPart/WindSpeedLevel[@refID='#{refid}']"]
						{
							area: area,
							td: td,
							range: [td.hour, td.hour+3],
							text: "#{direction.text}の風 #{clean_string(level.attribute("description").value.gsub("毎秒"){""})}"
						}
					end
			when "3時間毎気温"
				kind
					.elements
					.collect("TemperaturePart/jmx_eb:Temperature") do |part|
						td = time_define_by_part(time_define, part)
						{
							area: area,
							td: td,
							range: [td.hour, td.hour+3],
							text: "気温 #{part.text}度",
						}
					end
			end
		end
		
		def time_define time_series_info
			time_series_info
				.elements
				.collect("TimeDefines/TimeDefine") do |item|
					[item.attribute("timeId").value.to_i, Time.parse(item.elements["DateTime"].text)]
				end
				.to_h
		end
		
		def time_define_by_part time_define, part
			td = time_define[part.attribute("refID").value.to_i]
		end
	end
	
	def get_general_weather_conditions doc
		body = doc.elements["Report/Body"]
		body.elements["TargetArea/Name"].text+"\n"+
		clean_text_with_tabs(body.elements["Comment/Text"].text)+"\n"
	end
	
	
	def alert_info doc
		Alert::alert_info(doc)
	end
	Alert = Struct.new(:area, :alert) do
		extend GetInfo
		
		
		# 気象庁の警報のページ(海に面するか・どのようにまとめるかの情報を取る)で
		# 複数の情報を一ページに纏めている場合の変換テーブル
		ALERT_AREA_CONVERSION_HASH = {
			"上川地方" => "上川・留萌地方",
			"留萌地方" => "上川・留萌地方",
			"根室地方" => "釧路・根室・十勝地方",
			"釧路地方" => "釧路・根室・十勝地方",
			"十勝地方" => "釧路・根室・十勝地方",
			"胆振地方" => "胆振・日高地方",
			"日高地方" => "胆振・日高地方",
			"石狩地方" => "石狩・空知・後志地方",
			"空知地方" => "石狩・空知・後志地方",
			"後志地方" => "石狩・空知・後志地方",
			"渡島地方" => "渡島・檜山地方",
			"檜山地方" => "渡島・檜山地方",
			"鹿児島県（奄美地方除く）" => "鹿児島県",
			"奄美地方" => "鹿児島県",
		}
		# 警報・注意報の順位(特別警報・警報・注意報をすべてまとめたもの)
		ALERT_TYPE_RANKS = [
			"大雨","洪水","強風","暴風","風雪","暴風雪","大雪","波浪","高潮","雷","融雪","濃霧","乾燥","なだれ","低温","霜","着氷","着雪"
		]
		# 度合いの順位を兼ねる
		ALERT_TYPE_DEGREES = ["特別警報","警報","注意報"]
		# 状態の順位を兼ねる
		ALERT_TYPE_STATUSES = ["発表","継続","特別警報から警報","特別警報から注意報","警報から注意報","解除","発表警報・注意報はなし"]
		
		AlertAreaDetail = Struct.new(:name, :towns)
		AlertTownDetail = Struct.new(:name, :is_seaside) do
			alias_method :seaside?, :is_seaside
		end
		# 注意！ 発表警報・注意報なしの場合、status以外はnilになる！
		AlertKind = Struct.new(:name, :degree, :status) do
			def to_s
				if name.nil?
					status
				else
					"#{name}#{degree}(#{status})"
				end
			end
			def <=> o
				return 1 if name.nil?
				return -1 if o.name.nil?
				rd = ALERT_TYPE_DEGREES.index(degree) <=> ALERT_TYPE_DEGREES.index(o.degree)
				return rd unless rd == 0
				rs = ALERT_TYPE_STATUSES.index(status) <=> ALERT_TYPE_STATUSES.index(o.status)
				return rs unless rs == 0
				ALERT_TYPE_RANKS.index(name) <=> ALERT_TYPE_RANKS.index(o.name)
			end
		end
		
		# 都府県+地方がキーで、その中に地方:[市町村+地域]の配列がある。
		ALERT_DIVISION_FOR_COMBINED = YAML.load_file(File.expand_path(File.dirname(__FILE__))+"/alert-division.yaml")
			.map{|hp|
				pr = AlertAreaDetail.new(
					hp[:name],
					hp[:value]
						.map{|h1|
							h1[:value]
								.map{|h2|
									h2[:value]
										.map{|ht|
											AlertTownDetail.new(ht[:name], ht[:is_seaside])
										}
								}
						}
						.flatten,
				)
				
				d1 = hp[:value]
					.map{|h1|
						AlertAreaDetail.new(
							h1[:name],
							h1[:value]
								.map{|h2|
									h2[:value]
										.map{|ht|
											AlertTownDetail.new(ht[:name], ht[:is_seaside])
										}
								}
								.flatten,
						)
					}
				
				d2 = hp[:value]
					.map{|h1|
						h1[:value]
							.map{|h2|
								AlertAreaDetail.new(
									h2[:name],
									h2[:value]
										.map{|ht|
											AlertTownDetail.new(ht[:name], ht[:is_seaside])
										},
								)
							}
					}
				
				[pr.name, [pr,d1,d2].flatten]
			}
			.to_h
		
		def non_sea_alert
			@non_sea_alert ||= alert.reject{|kind|["波浪","高潮"].include?(kind.name)}
		end
		
		def self.generate_alert_from_xml doc
			area = doc.elements["Area/Name"].text
			alert = Alert::get_alert_info(doc)
			Alert.new(area, alert)
		end
		def self.get_alert_info doc
			if doc.elements["Kind/Status"].text=="発表警報・注意報はなし"
				Set.new [AlertKind.new(nil, nil, "発表警報・注意報はなし")] # とりあえず
			else
				kinds = doc.elements.to_a("Kind")
				kinds
					.map{|k|
						type, degree = k
							.elements["Name"]
							.text
							.match(/(#{Regexp.union(ALERT_TYPE_RANKS)})(#{Regexp.union(ALERT_TYPE_DEGREES)})/o)
							.captures
						AlertKind.new(type, degree, k.elements["Status"].text)
					}
					.to_set
			end
		end
		
		def self.alert_info doc
			alert_data = doc
				.elements
				.collect("Report/Body/Warning[@type=\"気象警報・注意報（市町村等）\"]/Item"){|i|
					generate_alert_from_xml(i)
				}
			alert_prefectures = doc.elements[
				"Report/Head/Headline/Information[@type=\"気象警報・注意報（府県予報区等）\"]/Item/Areas/Area/Name"].text
			
			summarized_alert_data = summarize_area(alert_data, alert_prefectures)
			
			alert_prefectures+"\n"+
			clean_text_with_tabs(doc.elements["Report/Head/Headline/Text"].text)+"\n"+
			alert_data
				.group_by{|area|area.alert.sort.to_a}
				.sort_by{|alert,areas|alert}
				.map{|alert, areas|
					"\t\t"+areas.map(&:area).join(" ")+
					"\n\t\t\t"+alert.sort.join(" ")+"\n"
				}
				.join("")
		end
		
		def self.summarize_area alert_data, alert_prefectures
			ALERT_DIVISION_FOR_COMBINED[
				ALERT_AREA_CONVERSION_HASH[alert_prefectures] || alert_prefectures
			]
				.each{|area_detail|
					# エリアが完全にかぶっているかどうか
					next unless (area_detail.towns.map{|town|town.name} - alert_data.map{|am|am.area}).empty?
					
					target_alert = alert_data.select{|as|area_detail.towns.find{|town|as.area==town.name}}
					
					first_target_alert_non_sea_alert = target_alert.first.non_sea_alert
					# すべての地域で海関連を除いた警報がすべて同じならば続ける
					next unless target_alert.all?{|alert|alert.non_sea_alert==first_target_alert_non_sea_alert}
					
					border_on_sea_alert_target = target_alert.select{|alert|area_detail.towns.find{|town|town.name==alert.area}.seaside?}
					# 海のある地域ですべての警報が同じならば続ける
					next unless border_on_sea_alert_target.all?{|alert|alert.alert==border_on_sea_alert_target.first.alert}
					
					new_alert = Alert.new(area_detail.name+"全域", target_alert.first.alert)
					alert_data.delete_if{|ad|area_detail.towns.find{|town|town.name==ad.area}}
					alert_data.unshift(new_alert)
				}
			alert_data
		end
		
	end
	
	def get_special_weather_report doc
		item = doc.elements["Report/Body/MeteorologicalInfos/MeteorologicalInfo/Item"]
		add_info = doc.elements["Report/Body/AdditionalInfo/ObservationAddition"]
		station = item.elements["Station"]
		loc = station.elements["Name"].text+((station.elements["Location"])? "("+station.elements["Location"].text+")" : "")
		"\n\t"+
		case doc.elements["Report/Head/Title"].text
		when "季節観測"
			item_text = ((add_info.elements["Text"].nil?)? "" : " "+delete_parentheses(add_info.elements["Text"].text))
			item.elements["Kind/Name"].text+item_text+" "+loc+"\n\t\t"+last_year_and_normal_year_text(add_info)
		when "特殊気象報（風）"
			"風 "+loc+"\n\t\t"+format_special_weather_report_wind(item)
		when "特殊気象報（各種現象）"
			item.elements["Kind/Name"].text+" "+loc+"\n\t\t"+
			clean_string(delete_parentheses(add_info.elements["Text"].text.tr("　", " ")))
		end
	end
	
	def format_special_weather_report_wind item
		item.elements.collect("Kind/Property/WindPart/*/") do |w|
				w.elements["jmx_eb:WindSpeed"].attributes["description"]+"  "+w.elements["jmx_eb:WindDegree"].attributes["description"]
			end.join("\n\t\t")
	end
	
	def creature_season_observation doc
		item = doc.elements["Report/Body/MeteorologicalInfos/MeteorologicalInfo/Item"]
		pos = item.elements["Station/Location"].text
		data = item.elements["Kind/Name"].text+
			"("+item.elements["Kind/ClassName"].text+", "+item.elements["Kind/Condition"].text+")"
		daytext = last_year_and_normal_year_text(doc.elements["Report/Body/AdditionalInfo/ObservationAddition"])
		
		pos+"\n\t"+data+"\n\t"+daytext
	end
	
	def rare_rain doc
		doc.elements["Report/Head/Headline/Information/Item/Areas/Area/Name"].text+"\n\t"+
		doc.elements["Report/Head/Headline/Text"].text.gsub("\n"){" "}
	end
	
	def local_maritime_alert_info doc
		doc.elements["Report/Body/MeteorologicalInfos/MeteorologicalInfo/Item/Area/Name"].text+"\n"+LocalMaritimeAlertInfo::alert_text(doc)
	end
	
	module LocalMaritimeAlertInfo
		module_function
		extend GetInfo
		
		def alert_text doc
			doc
				.elements
				.collect("Report/Body/Warning/Item"){|item|item}
				.group_by{|item|item.elements["Area/Name"].text}
				.sort_by{|k, v|k}
				.map{|(area, items)|"\t"+area+"\n\t\t"+items.map{|i|item_to_text(i)}.join("\n\t\t")}
				.join("\n")
		end
		
		def item_to_text item
			property = item.elements["Kind/Property"]
			text = property
				.elements
				.collect("WindPart|VisibilityPart|WaveHeightPart|IcingPart)"){|part|
					base = part.elements["SubArea/Base"]
					becoming = part.elements["SubArea/Becoming"]
					((part.elements["SubArea/AreaName"])? part.elements["SubArea/AreaName"].text+" " : "")+
					case part.name
					when "WindPart"
						wind_part(base, becoming, part)
					when "VisibilityPart"
						visibility_part(base, becoming)
					when "WaveHeightPart"
						part.elements["Sentence"].text
					when "IcingPart"
						icing_part(base, becoming)
					end}[0] if property
			item.elements["Kind/Name"].text+" : "+(text||"発表警報・注意報はなし")
		end
		
		def wind_part base, becoming, part
			wind_doc_to_text(base).gsub(/まる$/){"まり"}+
			((becoming)?
				"、"+wind_doc_to_text(becoming) : "")+
			((part.elements["SubArea/Remark"])? " "+part.elements["SubArea/Remark"].text : "")
		end
		
		def wind_doc_to_text doc
			((doc.elements["jmx_eb:WindDirection"])? doc.elements["jmx_eb:WindDirection"].text+"の風" : "")+
				doc.elements["jmx_eb:WindSpeed[not(@unit=\"ノット\")]/@description"].value
		end
		
		def visibility_part base, becoming
			visibility_doc_to_text(base)+
			((becoming)? "、"+becoming.elements["TimeModifier"].text+visibility_doc_to_text(becoming) : "")
		end
		
		def visibility_doc_to_text doc
			"視程"+doc.elements["jmx_eb:Visibility[not(@unit=\"海里\")]/@description"].value
		end
		
		def icing_part base, becoming
			icing_doc_to_text(base)+((becoming)? "、"+becoming.elements["TimeModifier"].text+icing_doc_to_text(becoming) : "")
		end
		
		def icing_doc_to_text doc
			((doc)? doc.elements["jmx_eb:Icing/@description"].value : "")
		end
	end
	
	def earthquake_info doc
		"\n\t"+((doc.elements["Report/Body/*/OriginTime"])? time_to_dhm_s(Time.parse(doc.elements["Report/Body/*/OriginTime"].text))+"発生\n\t" : "")+
		((doc.elements["Report/Head/Headline/Text/text()"])? (doc.elements["Report/Head/Headline/Text"].text.gsub("\n"){" "}) : "")+"\n"+
		EarthquakeInfo::info(doc)
	end
	
	# 一部の地震情報と津波情報は、違うタイトルで同じことをするものがあり、分けれないため、この関数内で地震情報と津波情報を処理する
	# それ以外のやつも一緒になってるのはCommentsとかだったりノリ
	module EarthquakeInfo
		module_function
		extend GetInfo
		
		def info doc
			doc.elements.collect("Report/Body/*") do |info|
				case info.name # whenのコメントはたぶん間違ってるとこがある
				when "Earthquake" # 震源に関する情報 + 震源・震度に関する情報 + 津波警報・注意報・予報a + 津波情報a + 沖合の津波観測に関する情報
					earthquake_paet(info)
				when "Intensity" # 震度速報 + 震源・震度に関する情報
					intensity_part(info)
				when "Tsunami" # 津波警報・注意報・予報a + 津波情報a + 沖合の津波観測に関する情報
					tsunami_part(info)
				when "Naming" # 地震の活動状況に関する情報
					"\t"+info.text+"\n"
				when "EarthquakeCount" # 地震回数に関する情報
					count_part(info)
				when "NextAdvisory" # 地震回数に関する情報
					clean_text_with_tabs(info.text)+"\n"
				when "Text" # すべて
					clean_text_with_tabs(info.text)+"\n"
				when "Comments" # すべて
					comment_part(info)
				end
			end.join
		end
		
		def earthquake_paet info
			area = info.elements["Hypocenter/Area"]
			"\t震源地:"+area.elements["Name/text()"].value+
			((area.elements["DetailedName"])? "("+area.elements["DetailedName/text()"].value+")" : "")+
			((area.elements["NameFromMark"])? "("+area.elements["NameFromMark/text()"].value+")" : "")+"\n\t"+
			"\t"+area.elements["jmx_eb:Coordinate/@description"].value+"\n\t"+
			"マグニチュード:"+info.elements["jmx_eb:Magnitude/@description"].value.sub("Ｍ"){}+"\n"+
			((info.elements["Hypocenter/Source"])? "\t情報元:"+info.elements["Hypocenter/Source/text()"].value+"\n" :  "")
		end
		
		def intensity_part info
			"\t最大震度:"+get_maxint(info.elements["Observation"])+"\n\t"+
			intensity_pref_xml_to_s(info)
		end
		def intensity_pref_xml_to_s info
			is_detail_info = info.elements["count(Observation/CodeDefine/Type)"]==4
			info.elements
				.collect("Observation/Pref"){|pref|
					get_name(pref)+((is_detail_info)? ":"+get_maxint(pref)+"\n\t" : "、")+
						intensity_area_xml_to_s(pref, is_detail_info)}
				.join("\n\t")+"\n"
		end
		def intensity_area_xml_to_s pref, is_detail_info
			# こっから先(city intensity_station)は震源・震度に関する情報のときだけ
			pref_name = get_name(pref)
			pref.elements
				.collect("Area"){|area|
					area_name = get_name(area)
					area_short_name = (area_name.start_with? pref_name)? area_name[pref_name.length..-1] : area_name
					area_short_name+":"+get_maxint(area)+
					((!is_detail_info)? "" : "\n\t\t"+intensity_city_xml_to_s(area))
				}
				.join((is_detail_info)? "\n\t" : "、")
		end
		def intensity_city_xml_to_s area
			area.elements
				.collect("City"){|city|get_name(city)+"、"+intensity_station_xml_to_s(city)}
				.join("\n\t\t")
		end
		def intensity_station_xml_to_s city
			city_name = get_name(city)
			city.elements
				.collect("IntensityStation"){|is|
					is_name = get_name(is)
					is_short_name = (is_name.start_with? city_name)? is_name[city_name.length..-1] : is_name
					is_short_name+":"+get_int(is)
				}
				.join("、")
		end
		def sint_to_s si
			# 震度のgsubは、震度5弱以上未入電のときの最初の震度を消すため。
			"震度"+si.gsub("震度"){""}.gsub("+"){"強"}.gsub("-"){"弱"}
		end
		def get_maxint doc
			sint_to_s(doc.elements["MaxInt/text()"].to_s)
		end
		def get_int doc
			sint_to_s(doc.elements["Int/text()"].to_s)
		end
		def get_name doc
			doc.elements["Name/text()"].value
		end
		
		def tsunami_part info
			"\t"+info.elements.collect("*") do |tinfo|
				case tinfo.name
				when "Observation"
					tsunami_observation_part(tinfo)
				when "Forecast"
					tsunami_forecast_part(tinfo)
				when "Estimation"
					tinfo.elements.collect("Item"){|item|item.elements["Area/Name"].text+"、"+max_height_xml_to_s(item)}.join("\n\t")
				end
			end.join("\n\t")+"\n"
		end
		def tsunami_observation_part tinfo
			is_offing = tinfo.elements["Item/Area/Name/text()"].nil?
			tinfo.elements.collect("Item"){|item|
				((is_offing)? "沖合での津波観測" : item.elements["Area/Name"].text)+"\n\t\t"+
				item.elements.collect("Station"){|sta|
					sta.elements["Name"].text+
					max_height_xml_to_s(sta)+
					((is_offing)? "("+sta.elements["Sensor"].text+")" : "")
				}.join("\n\t\t")}.join("\n\t")
		end
		def tsunami_forecast_part tinfo
			tinfo.elements.collect("Item") do |item|
				item.elements["Area/Name"].text+"、"+item.elements["Category/Kind/Name"].text+
				first_height_to_s(item, ->(t){time_to_dhm_s(t)})+
				((item.elements["MaxHeight/jmx_eb:TsunamiHeight/@description!=\"\""])? # ""になっている場合がある
					("、高さ:"+item.elements["MaxHeight/jmx_eb:TsunamiHeight/@description"].value) : "")+
				((!item.elements["Station"])? "" : "\n\t\t"+item.elements.collect("Station"){|sta|
						sta.elements["Name"].text+first_height_to_s(sta, ->(t){time_to_hm_s(t)})
					}.join("\n\t\t"))
			end.join("\n\t")
		end
		def first_height_to_s fh, time_to_s
			((!fh.elements["FirstHeight"])? "" :
				((fh.elements["FirstHeight/ArrivalTime"])?
					"、到達予想:"+time_to_dhm_s(Time.parse(fh.elements["FirstHeight/ArrivalTime"].text)) : "")+
				((fh.elements["FirstHeight/Condition"])? "、"+fh.elements["FirstHeight/Condition"].text : ""))
		end
		def max_height_xml_to_s doc
			((doc.elements["MaxHeight/DateTime"])? "、"+time_to_hm_s(Time.parse(doc.elements["MaxHeight/DateTime"].text)) : "")+
			((doc.elements["MaxHeight/Condition"])? "、"+doc.elements["MaxHeight/Condition"].text.gsub(/。$/){""} : "")+
			((doc.elements["MaxHeight/jmx_eb:TsunamiHeight"])?
				"、"+doc.elements["MaxHeight/jmx_eb:TsunamiHeight/@description"].value : "")+
			((doc.elements["MaxHeight/jmx_eb:TsunamiHeight/@condition"])?
				"、"+doc.elements["MaxHeight/jmx_eb:TsunamiHeight/@condition"].value : "")
		end
		
		def count_part info
			"\t"+info
				.elements.collect("Item"){|item|
					s = Time.parse(item.elements["StartTime"].text)
					e = Time.parse(item.elements["EndTime"].text)
					time_to_mdh_s(s)+"から"+
					time_to_mdh_s(e)+"までの"+
					time_diff_to_count_s(e-s)+"で、"+
					((item.elements["Number"].text!="-1")? (num=true; "回数:"+item.elements["Number"].text+"回") : "")+
					((item.elements["FeltNumber"].text!="-1")? ((num)? "、" : "")+"有感:"+item.elements["FeltNumber"].text+"回" : "")}
				.join("\n\t")+"\n"
		end
		
		def comment_part info
			info
				.elements
				.collect("*/Text||FreeFormComment"){|c|clean_text_with_tabs(c.text.gsub(/^\s+|\s+$/){""})}
				.select{|a|a!=nil && !(a.match(/^[ \t\n]+$/))}
				.join("\n")+"\n"
		end
	end
	
end
