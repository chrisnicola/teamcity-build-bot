require 'smirc'
require File.join(File.dirname(__FILE__),'build_listener')

class BuildBot
  def initialize(configuration)
    @configuration = configuration.is_a?(Mash) ? configuration : Mash.new(configuration)
    @listener = BuildListener.new(@configuration.feed)
    @irc = Smirc::Client.new(configuration)
    @threads = []
    @items = {}
    @verbose = @configuration.verbose  
  end

  def run
    Thread.abort_on_exception = true
    @listener.on(:log) {|l, m| print m}
    @listener.on(:item) {|l, i| process_item(i)}
    @irc.on(:connected) do |irc|
      irc.join(@configuration.channel)
      @threads << Thread.new do
        @listener.start
      end

    end

    @irc.on(:log) do |irc, m|
      print m
    end

    @irc.on(:message) do |irc, channel, msg, usr|
      parse_message(irc, channel, msg, usr)
    end

    @threads << Thread.new do
      @irc.connect
    end

    
    @threads.each {|t| t.join}
  end

  def parse_message(irc, channel, msg, usr)
    #puts "nick: #{@configuration.nickname}"
    case msg
    when Regexp.new("Hi|hi(.*)#{@configuration.nickname}")
      irc.message(channel, "Hi there, #{usr}")
    when /toggle verbose/
      @verbose = !@verbose
      irc.message(channel, "Ok, verbose is now #{@verbose}")
    end

  end

  def process_item(item)

    if @items.has_key?(item.guid)
      print("Item #{item} already known}")
      return
    end
    
    @items[item.guid] = item
    if item.failed || @verbose
      report_build(item)
    end
  end

  def report_build(item)
    @irc.message(@configuration.channel, "#{item.build} #{item.number} #{item.failed ? 'failed' : 'succeeded'}")
  end
    

  def stop
    @irc.disconnect
    #@threads.each {|t| t.stop}
  end
end



