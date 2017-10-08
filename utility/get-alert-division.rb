
require "open-uri"
require "yaml"

puts YAML.dump (1..56)
	.map{|i|
		sleep 1
		p i
		open("http://www.jma.go.jp/jp/warn/3#{i.to_s.rjust(2, "0")}_table.html").read}
	.map{|html|
		last_d1 = ""
		last_d2 = ""
		pref_value = html
			.match(/<table id='WarnTableTable'>(.*)<\/table>/)[1]
			.split("<tr")
			.select{|s|!s.empty?}
			.select{|s|!s.match(/\A(?: bgcolor="#ffff99">|><th rowspan="2" colspan="3" bgcolor="#bbbbbb">)/)}
			.select{|s|s!=">"}
			.map{|s|
				d1r = /<td rowspan="\d+" bgcolor="#bbbbbb">(.+?)<\/td>/
				d2r = /<td rowspan="\d+" bgcolor="#cccccc" align="center" style="padding: 3px 5px;">(.+?)<\/td>/
				cr = /<a href="f_\d+.html">(.+?)<\/a>/
				d1, d2, c, s = s.match(/\A>#{d1r}?#{d2r}?.*#{cr}(.*)\z/).captures
				{d1:d1, d2:((d2)? (d2.gsub("<br>"){""}) : nil), c:c, s:!s.match(/(class="il1")/)}}# d1=一時詳細区分 d2=二次詳細区分 c=市町村等 s=海と接しているか
			.map(){|h|
				last_d1 = h[:d1] || last_d1
				last_d2 = h[:d2] || last_d2
				[last_d1, last_d2, {name:h[:c], sea:h[:s]}]}
			.inject([]){|res, arr|
				d1, d2, data = arr
				unless res.find{|h|h[:name]==d1}
					res << {name:d1, value:[]}
				end
				d1h_array = res.find{|h|h[:name]==d1}[:value]
				unless d1h_array.find{|h|h[:name]==d2}
					d1h_array << {name:d2, value:[]}
				end
				d1h_array.find{|h|h[:name]==d2}[:value] << data
				res}
			{name:html.match(/<h1>気象警報・注意報 : (.+)<\/h1>/)[1], value:pref_value}
		}
