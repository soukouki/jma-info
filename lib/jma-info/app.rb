

def jma_info puts_lambdas
	begin
		start_time = Time.now
		info_uris_getter = JmaInfoGetter.new{|uris|puts_info(puts_lambdas, uris)}
		multiple_puts(puts_lambdas, "#{Time.now.strftime("%Y年%m月%d日%H時%M分%S秒")} 情報 起動\n	起動しました。\n")
		info_uris_getter.sync
	rescue Exception => e
		retry if error_process(start_time, Time.now, e)
	end
end


def multiple_puts lambdas, text
	lambdas.each{|l|l.call(text)}
end

def puts_info puts_lambdas, uris
	uris
		.map{|uri|GetInfo.get_info(uri)}
		.delete_if{|s|s.empty?}
		.each{|s|multiple_puts(puts_lambdas, s+"\n")}
end


def error_process start_time, error_time, error
	text = "#{Time.now}\n#{error.backtrace.first}: #{error.message} (#{error.class})\n#{error.backtrace[1..-1].each{|m|"\tfrom #{m}"}.join("\n")}\n"
	STDERR.puts text
	File::open(File::expand_path(__FILE__+"../../../../jma-info.debug.log"), "a"){|f|f.puts(text)}
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
