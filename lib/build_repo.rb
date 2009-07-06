class BuildRepo
  attr_accessor :name, :limit, :builds
  def initialize(name)
    @name = name
    @limit = 30
    @builds = []
  end
  
  def <<(item)
    return false if item.nil?
    @builds << item
    if @builds.size > @limit
      puts "I'm shifting"
      @builds.shift
    end
    
    @builds.sort! {|a,b| a.number <=> b.number}
  end

  def include?(item)
    o = @builds.detect{|b| b.number == item.number}
    !o.nil?
  end
  
  def latest_build
    @builds.last
  end
  
  def currently_failed?
    latest_build.nil? ? false : latest_build.failed
  end
end       
