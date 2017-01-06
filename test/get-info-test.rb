
require_relative "jma-info/get-info"

=begin 一般報
puts get_general_report("http://api.aitc.jp/jmardb/reports/2be7a5a8-11df-3fa4-954a-0b0b233884d2")
puts get_general_report("http://api.aitc.jp/jmardb/reports/2f1a794e-12c5-3538-a683-72db002c2b9a")
puts get_general_report("http://api.aitc.jp/jmardb/reports/7fa44ebf-64a1-32ab-9d99-379de6663211")
=end

=begin 概況
puts get_general_weather_conditions("http://api.aitc.jp/jmardb/reports/6220814d-3290-3722-be82-52855f47f800")
=end

=begin 注意報
puts get_alerm("http://api.aitc.jp/jmardb/reports/06ec89d7-67b5-3dad-9a54-5544ea0ae02d")
puts get_alerm("http://api.aitc.jp/jmardb/reports/9f2c7b54-171d-3bab-9c0b-81bdc410db16")
# 注意報解除
puts get_alerm("http://api.aitc.jp/jmardb/reports/0854e7f4-44e6-32bf-a78a-500a628cbbdd")
=end

=begin 季節観測・特殊気象報
puts get_special_weather_report("http://api.aitc.jp/jmardb/reports/8c13276d-3962-39c4-9344-46416963cd73")
puts get_special_weather_report("http://api.aitc.jp/jmardb/reports/8ca44e6c-6e97-37e8-81d8-e6576f6752cb")
puts get_special_weather_report("http://api.aitc.jp/jmardb/reports/a61ce04e-be36-3864-8a41-2430a826d748")
puts get_special_weather_report("http://api.aitc.jp/jmardb/reports/b5c0ab67-3e52-3ab3-adbf-395dcf848fa0")
puts get_special_weather_report("http://api.aitc.jp/jmardb/reports/b815b9a7-f1cb-32b4-a008-2dd25b9565ea")
=end

=begin 地方海上警報
puts get_local_maritime_alert("http://api.aitc.jp/jmardb/reports/7fdbc660-411a-3568-9025-4dab1777dde0")
puts get_local_maritime_alert("http://api.aitc.jp/jmardb/reports/9a8468ae-e420-3080-bbad-28146ab507ab")
puts get_local_maritime_alert("http://api.aitc.jp/jmardb/reports/961acdfc-8019-3b17-98cb-ea947f268d16")
=end
