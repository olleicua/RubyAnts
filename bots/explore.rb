=begin
  This ants bot simply makes each ant move randomly except that it will choose
  to move into a square that it has yet to visitted if possible.
  
  Sam Auciello | Marlboro College
  Jan 2012     | opensource.org/licenses/MIT
=end

# CONSTANTS #

Infinity = 1.0 / 0.0

# METHODS #

class Array
  def random
    self[rand self.size]
  end
end

class Square
  attr_accessor :visited
  attr_writer :boringness
  def to_s
    if self.land?
      return " "
    elsif self.water?
      return "#"
    elsif self.food?
      return "."
    elsif self.hill?
      return "o"
    elsif self.ant?
      return "a"
    end
  end
  def neighbors
    [:N, :S, :E, :W].map{|dir| self.neighbor dir}
  end
  def safe?
    not (self.ant? or self.water?)
  end
  def unsafe?
    not self.safe?
  end
  def targetable?
    self.safe? and (not @visited)
  end
  def getBoringness
    if @boringness.nil? and (not @searching)
      @searching = true
      @boringness = self.calculateBoringness
      @searching = false
    end
    return Infinity if @searching
    return @boringness
  end
  def calculateBoringness
    return Infinity if self.water?
    return 0 unless self.visited
    return self.neighbors.map{|square| square.getBoringness}.min + 1
  end
end

# MAIN #

# setup debug log
Log = open "log.txt", "w"

$:.unshift File.dirname($0)
require 'ants.rb'
ai = AI.new
ai.setup{}
ai.run do |ai| # this block is executed once for each turn
  
  Log.write "== turn #{ai.turn_number} ==\n"
  Log.flush
  
  # mark successfully visitted squares as visitted
  ai.map.each do |row|
    row.each do |square|
      square.boringness = nil
      square.visited = true if square.ant? and square.ant.mine?
    end
  end
  
  # each ant
  ai.my_ants.each do |ant|
    
    # pick a random safe move
    #move = [:N, :E, :S, :W] \
    #  .reject{|dir| ant.square.neighbor(dir).unsafe?} \
    #  .random
        
    # pick an unvisitted square if possible
    #[:N, :E, :S, :W].each do |dir|
    #  if ant.square.neighbor(dir).targetable?
    #    move = dir
    #  end
    #end
    move = [:N, :E, :S, :W] \
      .reject{|dir| ant.square.neighbor(dir).unsafe?} \
      .min do |dir1, dir2|
      ant.square.neighbor(dir1).getBoringness <=>
        ant.square.neighbor(dir2).getBoringness
    end
    
    b = [:N, :E, :S, :W].map{|d|ant.square.neighbor(d).getBoringness}
    
    Log.write " ant at #{ant.square.row},#{ant.square.col}: #{b}\n"
    
    # order the ant if a valid move exists
    if move
      ant.square.ant = nil
      ant.square.neighbor(move).ant = ant
      ant.order move
    end
  end
end
