# encoding: UTF-8

require "optparse"
require "securerandom"

require_relative "jma-info/updated-uris"
require_relative "jma-info/get-info"

def multiple_puts lambdas, text
	lambdas.each{|l|l.call(text)}
end

def app arg
	multiple_puts(arg[:puts], "起動しました。")
	uris_cache = UrisCache.NewCache(60*10, Time.now) # 10分以上aticの更新時刻が気象庁の発表時刻が遅れないとする
	loop do
		time = Time.now
		updated_uris, uris_cache = uris_cache.updated_uris(time)
		puts_info(arg[:puts], updated_uris, time)
		sleep(10)
	end
end

def puts_info(puts_lambdas, updated_uris, now_time)
	if updated_uris.empty?
		return
	end
	text = now_time.to_s+"\n"+
	updated_uris
		.map{|u|get_info(u)}
		.select{|s|!s.nil?}
		.join("\n")
	multiple_puts(puts_lambdas, text)
end

def file_appending f, s
	File::open(File::expand_path("../"+f, __FILE__), "a"){|f|f.puts s}
end

def yomi browser, str
	f_path = File.expand_path("../"+SecureRandom.uuid+".html", __FILE__)
	File::open(f_path, "w"){|f|f.puts js_yomi(str)}
	r = system(browser, f_path) or
		raise "ブラウザの立ち上げに失敗 : result=#{r.class}, browser=#{browser}, filepath=#{f_path}" # エラー処理
	Thread.new{sleep 5; File::delete(f_path)}
end
def js_yomi str
	speak_text = '"'+str.lines.map{|s|s.chomp.gsub(/([^。])$/){$1+"。"}}.join(%!"+\n"!)+'"'
	# 行末に「。」を追加しているのは、vivaldiで試したときに一息入れずに呼んだため。
	print_text = str.gsub("\n"){"<br>\n"}.gsub("\t"){"　　"}
	File::open("jma-info-data/yomi.html"){|io|io.set_encoding("utf-8").read}
		.gsub(/\#{([a-z_]+)}/){binding.local_variable_get($1)}
end

arg = {puts: [->(s){puts s}]}
OptionParser.new do |opt|
	opt.on("-w", "--write=[FILE]", "ファイルにログを保存する(デフォルトは\"./jma-info.log\")") do |f|
		f ||= "./jma-info.log"
		arg[:puts] << ->(s){file_appending(f, s)}
	end
	opt.on("-y", "--yomi=Browser", "読み上げる(引数にはブラウザのパスを指定してください)") do |b|
		arg[:puts] << ->(s){yomi(b, s)}
	end
	opt.parse!(ARGV)
end

begin
	app(arg)
rescue Exception => e
	text = e.to_s+e.backtrace.join("\n")
	puts text
	file_appending("./jma-info.debug.log", e.to_s+e.backtrace.join("\n"))
end
