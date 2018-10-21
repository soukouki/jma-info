# encoding: UTF-8

require "optparse"

$LOAD_PATH << "#{File.expand_path(File.dirname(__FILE__)+"/..")}/lib"

require "jma-info"

def optparse argv
	lambdas = [->(s){puts s}]
	OptionParser.new do |opt|
		opt.on("-w", "--write=[FILE]", "ファイルにログを保存する(デフォルトは\"./jma-info.log\")") do |f|
			f ||= "./jma-info.log"
			lambdas << ->(s){file_appending(f, s)}
		end
		opt.on("-s", "--system=[PATH]", "外部コマンドを実行する") do |path|
			lambdas << ->(s){`#{path} "#{s.gsub(/\t/){"        "}.gsub(/ /){"　"}.gsub(/\n/){"\\n"}.gsub(/\s+/){"_"}}"`}
		end
		opt.parse(argv)
	end
	return lambdas
end

application_loop(optparse(ARGV))
