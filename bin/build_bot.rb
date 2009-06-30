#! /usr/bin/env ruby
require "rubygems"
require File.join(File.dirname(__FILE__), "..","lib","buildbot")
options = YAML.load(File.open(File.join(File.dirname(__FILE__),"config.yml")))
b = BuildBot.new(options["config"])

begin
  b.run
ensure
  b.stop
end
