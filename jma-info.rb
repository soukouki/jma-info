# encoding: UTF-8

require "./jma-info/get-uri-list"

def sleep_up_to_even_number_minutes
	sleep(((Time.now.min+1)%2*60)+(60-Time.now.sec))
end

def get_info(uri_and_title)
	uri_and_title.title
end

old_uris = []#get_uri_list
loop do
	puts Time.now
	new_uris = get_uri_list
	puts (new_uris-old_uris).map{|nu|get_info(nu)}
	old_uris = new_uris
	sleep_up_to_even_number_minutes
end
