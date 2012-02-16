=begin
  This ants bot tries to move into unvisited spaces.
  
  Sam Auciello, Isaac Dupree | Marlboro College
  Jan-Feb 2012               | opensource.org/licenses/MIT
=end

# METHODS #

class Array
  def random
    if self.size == 0 then nil else self[rand self.size] end
  end
end

class Square
  # A square is "visited" if one of our ants have ever been in it.
  attr_accessor :visited

  # A (non-water) square's "boringness" is 0 if it's unvisited,
  # or N where N is the number of steps on land required to
  # get to an unvisited square.
  #
  # It's nil for water and squares that have no way at all
  # to get to an unvisited square (which includes if all squares
  # have been visited -- admittedly that may mean we've
  # occupied all the opponents' nests and thus won already.
  # TODO do something sensible then.).
  attr_accessor :boringness

  def neighbors
    [:N, :E, :S, :W].map{|dir| self.neighbor dir}
  end
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
  def unvisited?
    not self.visited
  end
  def interesting?
    self.land? and (self.unvisited? or self.food?)
  end
end

# MAIN #

# setup debug log
Log = open "log.txt", "w"
def log v
  Log.write v
  Log.write "\n"
  Log.flush
end

def unexploredSquares map
  map.flatten(1).reject{|square| not square.interesting?}
end

# frontier is an array!
def calculateSquaresBoringness map, frontier = (unexploredSquares map), currentBoringness = 0
  ""
  log "sz #{frontier.size}"
  return if frontier.size == 0

  newFrontier = []

  log "go go gogogo!"
  frontier.each do |square|
#    log "yo #{square.row} #{square.col}  #{square.boringness == nil and not square.water?}"
    if square.boringness == nil and not square.water?
      square.boringness = currentBoringness
      newFrontier.push(*square.neighbors) #.reject{|neighbor| neighbor.boringness != nil or neighbor.water?}
    end
  end
  log "rec #{currentBoringness}"
  calculateSquaresBoringness(map, (newFrontier.uniq.reject{|neighbor| neighbor.boringness != nil or neighbor.water?}), (currentBoringness+1))
end

$:.unshift File.dirname($0)
require 'ants.rb'
ai = AI.new
ai.setup do
  log "hello"
end
ai.run do |ai| # this block is executed once for each turn
  log "hi turn #{ai.turn_number}"
  # mark successfully visitted squares as visitted
  ai.map.each do |row|
    row.each do |square|
      square.visited = true if square.ant? and square.ant.mine?
      square.boringness = nil
    end
  end

  calculateSquaresBoringness ai.map
  
  ai.my_ants.each do |ant|
    possibleNeighbors = ant.square.neighbors.reject{|neighbor| neighbor.unsafe? or neighbor.boringness == nil}
    if possibleNeighbors.size > 0
      log "best? #{possibleNeighbors.map{|neighbor| neighbor.boringness}}"
      best = possibleNeighbors.map{|neighbor| neighbor.boringness}.min
      log "best #{best}"
      move = [:N, :E, :S, :W] \
        .reject{|dir| ant.square.neighbor(dir).unsafe? or ant.square.neighbor(dir).boringness != best} \
        .random
    
      if move
        ant.order move
        ant.square.neighbor(move).ant = ant
        ant.square.ant = nil
      end
    end
  end
end

