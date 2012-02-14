=begin
  This ants bot simply makes each ant move randomly except that it will not move
  into a wall or another ant.
  
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
  def safe?
    not (self.ant? or self.water?)
  end
  def unsafe?
    not self.safe?
  end
end

# MAIN #

# setup debug log
Log = open "log.txt", "w"

$:.unshift File.dirname($0)
require 'ants.rb'

ai = AI.new

ai.setup{}

ai.run do |ai|
  ai.my_ants.each do |ant|
    move = [:N, :E, :S, :W] \
      .reject{|dir| ant.square.neighbor(dir).unsafe?} \
      .random
    if move
      ant.square.neighbor(move).ant = ant
      ant.order move
    end
  end
end
