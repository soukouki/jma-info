# encoding: UTF-8

require "open-uri"
require "optparse"
require "securerandom"

require_relative "jma-info/get-uri-list"
require_relative "jma-info/get-info"

def sleep_up_to_even_number_minutes
	loop_sec = 30 # 60で割り切れるように
	sleep(loop_sec-(Time.now.sec%loop_sec))
end

def multiple_puts lambdas, text
	lambdas.each{|lam|lam.call(text)}
end

def app arg
	old_date = Time.now-120
	multiple_puts(arg[:puts], "起動しました。")
	loop do
		new_date = Time.now
		uri_list = get_uri_list(old_date, new_date)
		text = ((uri_list.empty?)? "" : new_date.to_s+"\n")+
		uri_list
			.map{|u|get_info(u)}
			.select{|s|!s.nil?}
			.join("\n")
		multiple_puts(arg[:puts], text) unless text==""
		old_date = new_date
		sleep_up_to_even_number_minutes
	end
end

def file_appending f, s
	File::open(File::expand_path("../"+f, __FILE__), "a"){|f|f.puts s}
end

def yomi browser, str
	f_path = File.expand_path("../"+SecureRandom.uuid+".html", __FILE__)
	File::open(f_path, "w"){|f|f.puts js_yomi(str)}
	`#{browser} #{f_path}`
	Thread.new{sleep 5; File::delete(f_path)}
end

def js_yomi str
	<<-"EOS"
<p>#{str.gsub("\n"){"<br>"}.gsub("\t"){"　　"}}</p>
<script>
var ssu = new SpeechSynthesisUtterance();
ssu.text = #{str.lines.map{|s|"'#{s.chomp}。'"}.join("+\n")};
ssu.lang = 'ja-JP';
ssu.onend = function(){window.close()};
speechSynthesis.speak(ssu);
</script>
	EOS
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
	file_appending("./jma-info.debug.log", e.class)
end
