# encoding: UTF-8

require "open-uri"


require "./jma-info/get-uri-list"
require "./jma-info/get-info"

def sleep_up_to_even_number_minutes
	sleep(((Time.now.min+1)%2*60)+(60-Time.now.sec))
end

old_uris = []#get_uri_list
old_date = Time.now-120
loop do
	puts new_date = Time.now
	new_uris = get_uri_list(old_date, new_date)
	(new_uris-old_uris).lazy.map{|u|get_info(u)}.select{|s|!s.nil?}.each{|s|puts s} # 全体が揃う前に表示を始める
	old_uris = new_uris
	sleep_up_to_even_number_minutes
end
