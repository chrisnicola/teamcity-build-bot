#! /usr/bin/env ruby
require "rubygems"
require File.join(File.dirname(__FILE__), "..","lib","buildbot")
options = {
  :server => "irc.freenode.net",
  :nickname => "mrbigglesworth55",
  :realname => "bigglesmalls",
  :port => 6667,
  :channel => "#radam",
  :feed => "http://seafreaiptrac.dev.gettyimages.net:8111/guestAuth/feed.html?itemsType=builds&buildStatus=successful&buildStatus=failed&userKey=guest",
  :verbose => false
}


b = BuildBot.new(options)
begin
  b.run
ensure
  b.stop
end
