require 'hpricot'
require 'eventful'
require 'open-uri'
require File.join(File.dirname(__FILE__), "build_item")

class BuildListener
  include Eventful

  def initialize(feed, sleep_time = 90)
    @feed_url = feed
    @sleep_time = sleep_time
  end
  
  def start
    loop do
      xml = Hpricot.XML(open(@feed_url))
      (xml/:entry).each do |entry|
        process_entry(entry)
      end

      sleep(@sleep_time)
    end
  end
  
  def stop

  end

  def process_entry(entry)
    title = (entry/:title).inner_html
    link = (entry/:link).attr("href")
    item = BuildItem.new(title, link)
#    log("Title: #{title}")
    #log("Link: #{link}")
    #log("Item: #{item.build} / #{item.number} / #{item.failed}")
    fire(:item, item)
  end


  def log(msg)
    fire(:log, msg)
  end
end
