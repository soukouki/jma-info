# encoding: UTF-8

require "open-uri"
require "optparse"
require "securerandom"

require_relative "jma-info/get-uri-list"
require_relative "jma-info/get-info"

def multiple_puts lambdas, text
	lambdas.each{|l|l.call(text)}
end

def app arg
	old_date = Time.now
	multiple_puts(arg[:puts], "起動しました。")
	loop do
		new_date = Time.now # puts_infoは時間のかかる処理なのでその分を取り逃がさないように
		puts_info(arg[:puts], new_date, old_date)
		old_date = new_date
		sleep(10)
	end
end

def puts_info(puts_lambdas, new_date, old_date)
	uri_list = get_uri_list(old_date, new_date)
	if uri_list.empty?
		return
	end
	text = ((uri_list.empty?)? "" : new_date.to_s+"\n")+
	uri_list
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
