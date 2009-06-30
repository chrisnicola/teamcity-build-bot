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
    @listener.on(:log) {|l, m| print "LIS #{m}\n"}
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
    case msg
    when Regexp.new("Hi|hi(.*)#{@configuration.nickname}")
      irc.message(channel, "Hi there, #{usr}")
    when Regexp.new("#{@configuration.nickname}(.*)status")
      irc.message(channel, "I am running")
      irc.message(channel, "Verbose is: #{@verbose}")
    when /life(.*)universe(.*)everything/
      irc.message(channel, "42")
    when /prom/
      irc.message(channel, "Just take your sister, dum-dum.  She's a girl!")
    when /toggle verbose/
      @verbose = !@verbose
      irc.message(channel, "Ok, verbose is now #{@verbose}")
    end

  end

  def process_item(item)

    return if @items.has_key?(item.guid)
    
    @items[item.guid] = item
    if item.failed || @verbose
      report_build(item)
    end
  end

  def report_build(item)
    @irc.message(@configuration.channel, "#{item.build} #{item.number} #{item.failed ? 'failed' : 'succeeded'}")
    @irc.message(@configuration.channel, "#{item.link}")
  end
    

  def stop
    @irc.disconnect
  end
end



