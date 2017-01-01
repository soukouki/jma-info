# encoding: UTF-8

require "open-uri"


require "./jma-info/get-uri-list"
require "./jma-info/get-info"

def file_write_and_print str
	puts str
	open("jma-info.log", "a"){|f|f.puts(str)}
end

def puts_info new_uris, old_uris
	(new_uris-old_uris)
		.lazy # 少しずつ表示していく
		.map{|u|get_info(u)}
		.select{|s|!s.nil?}
		.each{|s|file_write_and_print s}
end

def sleep_up_to_even_number_minutes
	sleep(((Time.now.min+1)%2*60)+(60-Time.now.sec))
end

old_uris = []#get_uri_list
old_date = Time.now-120
loop do
	file_write_and_print new_date = Time.now
	new_uris = get_uri_list(old_date, new_date)
	puts_info(new_uris, old_uris)
	old_uris = new_uris
	sleep_up_to_even_number_minutes
end
