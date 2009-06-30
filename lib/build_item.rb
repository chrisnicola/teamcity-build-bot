class BuildItem
  attr_accessor :title, :link, :build, :number, :failed
  def initialize(title, link)
    @title = title
    @link = link
    @failed = false
    get_data_from_title
  end

  def get_data_from_title
    @title =~ /Build (\D+) #(\d+)/
    @build = $1
    @number = $2.to_i
    @failed = true if @title =~ /fail/
  end

  def guid
    @guid ||= "#{build}:#{number}"
  end
end

