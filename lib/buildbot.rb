require 'smirc'
require File.join(File.dirname(__FILE__),'build_listener')
require File.join(File.dirname(__FILE__),'build_repo')

class BuildBot
  def initialize(configuration)
    @configuration = configuration.is_a?(Mash) ? configuration : Mash.new(configuration)
    @listener = BuildListener.new(@configuration.feed)
    @irc = Smirc::Client.new(configuration)
    @threads = []
    @items = {}
    @repos = {}
    @verbose = @configuration.verbose  
    @has_reported = false
  end

  def run
    load_data
    Thread.abort_on_exception = true
    @listener.on(:log) {|l, m| print "LIS #{m}\n"}
    @listener.on(:item) {|l, i| @has_reported = true; process_item(i)}
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
#    when Regexp.new("Hi|hi(.*)#{@configuration.nickname}")
      #irc.message(channel, "Hi there, #{usr}")
    when Regexp.new("#{@configuration.nickname}(.*) config status")
      irc.message(channel, "I am running")
      irc.message(channel, "Verbose is: #{@verbose}")

    when Regexp.new("#{@configuration.nickname}(.*) build status")
      irc.message(channel, "Known builds:")
      @repos.keys.each do |k|
        irc.message(channel, "#{k}: ##{@repos[k].latest_build.number} #{@repos[k].latest_build.failed ? 'failed' : 'succeeded'}")
      end
    when /status of (.*)/
      if @repos.has_key?($1)
        report_build(@repos[$1].latest_build, false)
      end
    when /history of (.*)/
      if @repos.has_key?($1)
        @repos[$1].builds.reverse[0..10].each do |b|
          report_build(b, false)
        end
      end
    when /Load Extort:UN/
      irc.message(channel, "................. *UN contacted*.......")
      sleep(5)
      irc.message(channel, "GENTLEMEN! WE HAVE THE DOOMSDAY DEVICE!")
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

    unless @repos.has_key?(item.build)
      @repos[item.build] = BuildRepo.new(item.build)
    end
    build = @repos[item.build]
    unless build.include?(item)
      #print "build #{build.name} did not include #{item.title}\n"
      #build.builds.each do |b|
        #print b.title + "\n"
      #end

      if item.failed || @verbose
        report_build(item)
      elsif build.currently_failed? && !item.failed
        report_build(item, false)
      end
      build << item 
    end

    
  end

  def report_build(item, include_link = true)
    @irc.message(@configuration.channel, "#{item.build} #{item.number} #{item.failed ? 'failed' : 'succeeded'}")
    if include_link
      @irc.message(@configuration.channel, "#{item.link}")
    end
  end
    

  def stop
    save_data if @has_reported
    @irc.disconnect
  end

  def load_data
    if File.exist?('saved_data')
      @repos = Marshal.load(File.open('saved_data'))
    end
  end

  def save_data
    puts "SAVING DATA"
    File.open("saved_data", "w+") do |f|
      Marshal.dump(@repos, f)
    end
  end
end



