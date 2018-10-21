

def application_loop puts_lambdas
	begin
		start_time = Time.now
		multiple_puts(puts_lambdas, "#{Time.now.strftime("%Y年%m月%d日%H時%M分%S秒")}\n	起動しました。\n")
		uris_cache = UrisCache.NewCache(60*5) # 5分以上aticの更新時刻が気象庁の発表時刻から遅れないとする
		loop do
			time = Time.now
			updated_uris, uris_cache = uris_cache.updated_uris(time)
			puts_info(puts_lambdas, updated_uris, time) unless updated_uris.empty?
			sleep(20)
			
			sleep 30 # テスト用！ 終わったら消すこと！
			error
		end
	rescue Exception => e
		retry if error_process(start_time, Time.now, e)
	end
end


def multiple_puts lambdas, text
	lambdas.each{|l|l.call(text)}
end

def puts_info(puts_lambdas, updated_uris, now_time)
	updated_uris
		.map{|u|GetInfo.get_info(u)}
		.select{|s|!s.empty?}
		.each{|s|multiple_puts(puts_lambdas, s+"\n")}
end


def error_process start_time, error_time, error
	text = "#{Time.now}\n#{error.backtrace.first}: #{error.message} (#{error.class})\n#{error.backtrace[1..-1].each{|m|"\tfrom #{m}"}.join("\n")}\n"
	STDERR.puts text
	File::open(File::expand_path(__FILE__+"../../../../jma-info.debug.log")), "a"){|f|f.puts(text)}
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
