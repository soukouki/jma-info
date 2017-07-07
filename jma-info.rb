# encoding: UTF-8

require "optparse"

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
	multiple_puts(arg[:puts], "#{Time.now.strftime("%Y年%m月%d日%H時%M分%S秒")}\n	起動しました。")
	uris_cache = UrisCache.NewCache(60*5, Time.now) # 10分以上aticの更新時刻が気象庁の発表時刻から遅れないとする
	loop do
		time = Time.now
		updated_uris, uris_cache = uris_cache.updated_uris(time)
		puts_info(arg[:puts], updated_uris, time) unless updated_uris.empty?
		sleep(15)
	end
end

def puts_info(puts_lambdas, updated_uris, now_time)
	text = updated_uris
		.map{|u|GetInfo::get_info(u)}
		.select{|s|!s.nil?}
		.join("\n")
	return if text==""
	multiple_puts(puts_lambdas, text)
end

def file_appending f, s
	file_open(f, "a"){|f|f.puts s}
end

def optparse argv
	arg = {puts: [->(s){puts s}]}
	OptionParser.new do |opt|
		opt.on("-w", "--write=[FILE]", "ファイルにログを保存する(デフォルトは\"./jma-info.log\")") do |f|
			f ||= "./jma-info.log"
			arg[:puts] << ->(s){file_appending(f, s)}
		end
		opt.on("-s", "--system=[PATH]", "外部コマンドを実行する") do |path|
			arg[:puts] << ->(s){`#{path} "#{s.gsub(/ /){"　"}.gsub(/\t/){"　　"}.gsub(/\n/){"　　　　"}.gsub(/\s+/){"_"}}"`}
		end
		opt.parse(argv)
	end
	return arg
end

def error_process start_time, error_time, error
	text = "#{Time.now}\n#{error.backtrace.first}: #{error.message} (#{error.class})\n#{error.backtrace[1..-1].each{|m|"\tfrom #{m}"}.join("\n")}"
	STDERR.puts text
	file_appending("./jma-info.debug.log", error.to_s+error.backtrace.join("\n"))
	puts "起動時間 #{Time.now-start_time}"
	if Time.now-start_time > 60
		STDERR.puts "60秒以上起動した後にエラーが発生したので、もう一度やり直します。"
		STDERR.puts "拾い漏れるデータがある可能性があります。"
		STDERR.puts "プログラムを終了させるには、もう一度Ctrl+cを送ってください。"
		return true
	else
		return false
	end
end

begin
	arg = optparse(ARGV)
	start_time = Time.now
	app(arg)
rescue Exception => e
	retry if error_process(start_time, Time.now, e)
end
