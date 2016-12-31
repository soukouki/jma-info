
require "./jma-info/get-info"

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
