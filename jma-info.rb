# encoding: UTF-8

require "optparse"
require "securerandom"

require_relative "jma-info/updated-uris"
require_relative "jma-info/get-info"

def multiple_puts lambdas, text
	lambdas.each{|l|l.call(text)}
end

def absolute_path path
	File::expand_path(path, __FILE__+"/..")
end

def file_open name, open_type="r", &open_block
	File::open(absolute_path(name), open_type, &open_block)
end

def app arg
	multiple_puts(arg[:puts], "#{Time.now}\n	起動しました。")
	uris_cache = UrisCache.NewCache(60*10, Time.now) # 10分以上aticの更新時刻が気象庁の発表時刻から遅れないとする
	loop do
		time = Time.now
		updated_uris, uris_cache = uris_cache.updated_uris(time)
		puts_info(arg[:puts], updated_uris, time)
		sleep(15)
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
	file_open(f, "a"){|f|f.puts s}
end

arg = {puts: [->(s){puts s}]}
OptionParser.new do |opt|
	opt.on("-w", "--write=[FILE]", "ファイルにログを保存する(デフォルトは\"./jma-info.log\")") do |f|
		f ||= "./jma-info.log"
		arg[:puts] << ->(s){file_appending(f, s)}
	end
	opt.on("-s", "--system=[PATH]", "外部コマンドを実行する") do |path|
		arg[:puts] << ->(s){`#{path} #{s.gsub(/\s/){"。"}}`}
	end
	opt.parse(ARGV)
end

begin
	start_time = Time.now
	app(arg)
rescue Exception => e
	text = e.to_s+e.backtrace.join("\n")
	puts text
	file_appending("./jma-info.debug.log", e.to_s+e.backtrace.join("\n"))
	puts "起動時間 #{Time.now-start_time}"
	if Time.now-start_time > 300
		puts "300秒以上起動した後にエラーが発生したので、もう一度やり直します"
		puts "拾い漏れるデータがある可能性があります"
		retry
	end
end
