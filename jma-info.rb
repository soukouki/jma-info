# encoding: UTF-8

require "open-uri"


require "./jma-info/get-uri-list"
require "./jma-info/get-info"

def sleep_up_to_even_number_minutes
	sleep(((Time.now.min+1)%2*60)+(60-Time.now.sec))
end

old_uris = []#get_uri_list
loop do
	puts Time.now
	new_uris = get_uri_list
	(new_uris-old_uris).each{|nu|print get_info(nu)} # 全体が揃う前に表示を始める
	old_uris = new_uris
	sleep_up_to_even_number_minutes
end
