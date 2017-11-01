
require_relative "./updated-uris"
require_relative "./get-info"


def app arg
	multiple_puts(arg[:puts], "#{Time.now.strftime("%Y年%m月%d日%H時%M分%S秒")}\n	起動しました。\n")
	uris_cache = UrisCache.NewCache(60*5) # 5分以上aticの更新時刻が気象庁の発表時刻から遅れないとする
	loop do
		time = Time.now
		updated_uris, uris_cache = uris_cache.updated_uris(time)
		puts_info(arg[:puts], updated_uris, time) unless updated_uris.empty?
		sleep(20)
	end
end

def multiple_puts lambdas, text
	lambdas.each{|l|l.call(text)}
end

def puts_info(puts_lambdas, updated_uris, now_time)
	updated_uris
		.map{|u|GetInfo::get_info(u)}
		.select{|s|!s.empty?}
		.each{|s|multiple_puts(puts_lambdas, s+"\n")}
end


# 軽いライブラリ的なもの

def file_appending f, s
	file_open(f, "a"){|f|f.puts s}
end

def absolute_path path
	File::expand_path(path, __FILE__+"/..")
end

def file_open name, open_type="r", &open_block
	File::open(absolute_path(name), open_type, &open_block)
end

def error_loop arg
	begin
		start_time = Time.now
		app(arg)
	rescue Exception => e
		retry if error_process(start_time, Time.now, e)
	end
end

def error_process start_time, error_time, error
	text = "#{Time.now}\n#{error.backtrace.first}: #{error.message} (#{error.class})\n#{error.backtrace[1..-1].each{|m|"\tfrom #{m}"}.join("\n")}\n"
	STDERR.puts text
	file_appending("../jma-info.debug.log", text) # パスはこのファイルからの相対パス
	puts "起動時間 #{Time.now-start_time}"
	if Time.now-start_time > 30
		STDERR.puts "30秒以上起動した後にエラーが発生したので、もう一度やり直します。"
		STDERR.puts "拾い漏れるデータがある可能性があります。"
		STDERR.puts "プログラムを終了させるには、もう一度Ctrl+cを送ってください。"
		return true
	else
		return false
	end
end
