=begin
  This ants bot simply makes each ant move randomly except that it will choose
  to move into a square that it has yet to visitted if possible.
  
  Sam Auciello | Marlboro College
  Jan 2012     | opensource.org/licenses/MIT
=end

# METHODS #

class Array
  def random
    self[rand self.size]
  end
end

class Square
  attr_accessor :visited
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
  def safe?
    not (self.ant? or self.water?)
  end
  def unsafe?
    not self.safe?
  end
  def targetable?
    self.safe? and (not @visited)
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
  
  # mark successfully visitted squares as visitted
  ai.map.each do |row|
    row.each do |square|
      square.visited = true if square.ant? and square.ant.mine?
    end
  end
  
  # each ant
  ai.my_ants.each do |ant|
    
    # pick a random safe move
    move = [:N, :E, :S, :W] \
      .reject{|dir| ant.square.neighbor(dir).unsafe?} \
      .random
        
    # pick an unvisitted square if possible
    [:N, :E, :S, :W].each do |dir|
      if ant.square.neighbor(dir).targetable?
        move = dir
      end
    end
    
    # order the ant if a valid move exists
    if move
      ant.square.neighbor(move).ant = ant
      ant.order move
    end
  end
end
