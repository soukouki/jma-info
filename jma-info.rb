# encoding: UTF-8

require "open-uri"


require "./jma-info/get-uri-list"
require "./jma-info/get-info"

def file_write_and_print str
	puts str
	open("jma-info.log", "a"){|f|f.puts(str)}
end

def puts_info uris
	uris
		.lazy # 少しずつ表示していく
		.map{|u|get_info(u)}
		.select{|s|!s.nil?}
		.each{|s|file_write_and_print s}
end

def sleep_up_to_even_number_minutes
	loop_sec = 30 # 60で割り切れるように
	sleep(loop_sec-(Time.now.sec%loop_sec))
end

old_date = Time.now-120
loop do
	new_date = Time.now
	uri_list = get_uri_list(old_date, new_date)
	file_write_and_print new_date unless uri_list.empty?
	puts_info(uri_list)
	old_date = new_date
	sleep_up_to_even_number_minutes
end
