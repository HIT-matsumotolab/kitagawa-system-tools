require 'mysql2'

client = Mysql2::Client.new(:host => 'localhost', :user => 'root', :password => 'root')
