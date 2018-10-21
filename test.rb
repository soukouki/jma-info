# coding: UTF-8

$LOAD_PATH << "#{File.expand_path(File.dirname(__FILE__))}/lib"

require "jma-info"

Dir["../jma-info/test/**/*.rb"].each{|f|puts f; require f}
