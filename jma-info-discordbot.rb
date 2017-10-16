# encoding: UTF-8

require "discordrb"
require_relative "jma-info/app"


def message channels, s
	text = s.gsub(/(?<![*_~])([*_~])(?![*_~])/){"\\"+$1}
	until text.empty?
		# 2000文字制限への対策。0..1999は2000文字
		p_text = text[0..1999].gsub(/(\A.*\n).*\z/){$1}
		text = text[p_text.length..-1]
		channels.each{|ch|ch.send_message(p_text, tts=false)}
	end
end


puts <<'EOS'
ここでサーバーに参加し、
https://discordapp.com/oauth2/authorize?client_id=#{client_id}&scope=bot&permissions=0
実行してください。

usage:
jma-info-discordbot.rb [client_id] [token] [*channel_ids]
EOS

exit if ARGV.length < 3
client_id, token, *channel_ids = ARGV

bot = Discordrb::Bot.new(
		token: token,
		client_id: client_id)
channels = channel_ids.map{|id|bot.channel(id)}

error_loop({puts: [->(s){puts s}, ->(s){message(channels, s)}]})
