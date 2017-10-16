# encoding: UTF-8

require "optparse"
require_relative "jma-info/app.rb"

def optparse argv
	arg = {puts: [->(s){puts s}]}
	OptionParser.new do |opt|
		opt.on("-w", "--write=[FILE]", "ファイルにログを保存する(デフォルトは\"./jma-info.log\")") do |f|
			f ||= "./jma-info.log"
			arg[:puts] << ->(s){file_appending(f, s)}
		end
		opt.on("-s", "--system=[PATH]", "外部コマンドを実行する") do |path|
			arg[:puts] << ->(s){`#{path} "#{s.gsub(/\t/){"        "}.gsub(/ /){"　"}.gsub(/\n/){"\\n"}.gsub(/\s+/){"_"}}"`}
		end
		opt.parse(argv)
	end
	return arg
end

error_loop(optparse(ARGV))
