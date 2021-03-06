=begin
  This ants bot tries to move towards enemy hills, food, and
  unvisited spaces.
  
  Sam Auciello, Isaac Dupree | Marlboro College
  Jan-Feb 2012               | opensource.org/licenses/MIT
=end

# CONSTANTS #

Infinity = 1.0 / 0.0
LargeFiniteNumber = 100000000
OurOwnerID = 0
CardinalDirections = [:N, :S, :E, :W]

# METHODS #

class Array
  def random
    if self.size == 0 then nil else self[rand self.size] end
  end
end

class Square
  # A square is "visited" if one of our ants have ever been in it.
  attr_accessor :visited
  
  # @boringnesses = { :unseen => n, :food => n, :enemyHill => n }
  #
  # A (non-water) square's "boringness" of a type is 0 if it's
  # unvisited / food / an enemy hill (respectively),
  # or N where N is the number of steps on land required to
  # get to an interesting (n=0) square.
  #
  # "n" is nil for water and squares that have no way at all
  # to get to an interesting square of the given type.
  attr_accessor :boringnesses

  def neighbors
    CardinalDirections.map{|dir| self.neighbor dir}
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

  # rateBoringness returns a number whose useful property is that:
  # On any given turn, between any two squares that are equally
  # easy to get to (e.g. among an ant's neighbor squares),
  # a square with a lower number is a better one to go to
  # (provided it's safe).
  def rateBoringness
    distanceToUnseen = boringnesses[:unseen]    || LargeFiniteNumber
    distanceToFood   = boringnesses[:food]      || LargeFiniteNumber
    distanceToEnemy  = boringnesses[:enemyHill] || LargeFiniteNumber
    # Apply a sub-linear function to each distance so that
    # farther away distances have less influence than close.
    # Food is more important than unexplored spaces.
    # Enemy nests are even more important(?).
    # Using a continuous function (rather than e.g. if distanceToFood < 6)
    # makes it easier to write a function that can fairly compare any
    # two locations we're considering moving to, even when the two
    # locations fall on different sides of that threshold.
    result = Math.sqrt(distanceToUnseen) + Math.sqrt(distanceToFood*2) + Math.sqrt(distanceToEnemy*3)
    log "#{@col},#{@row} boringness: #{distanceToUnseen}, #{distanceToFood}, #{distanceToEnemy} ==> #{result}"
    return result
  end
end

class AI
  def unexploredSquares
    @map.flatten(1).reject{|square| not square.interesting?}
  end
  def enemyHills
    @map.flatten(1).reject{|square| not (square.hill? and square.hill? != OurOwnerID)}
  end
  def foods
    @map.flatten(1).reject{|square| not square.food?}
  end

  def calculateBoringnesses
    calculateBoringness :unseen, self.unexploredSquares
    calculateBoringness :food, self.foods
    calculateBoringness :enemyHill, self.enemyHills
  end

  private
  # calculateBoringness does a breadth-first traversal
  # over land squares from a given set ('frontier' array) of
  # "interesting" land squares.
  #
  # It marks each square with the number of N/S/E/W steps on land
  # needed to reach an interesting square.  It does not mark
  # squares that are inaccessible from the given "interesting" squares.
  def calculateBoringness type, frontier, currentBoringness=0
    return if frontier.size == 0
    
    newFrontier = []
    
    frontier.each do |square|
      if square.boringnesses[type] == nil and not square.water?
        square.boringnesses[type] = currentBoringness
        
        # is this filter more efficient before or after the loop?
        relevantNeighbors = square.neighbors.reject do |neighbor|
          neighbor.boringnesses[type] != nil or neighbor.water?
        end
        
        newFrontier.push *relevantNeighbors
      end
    end
    calculateBoringness type, newFrontier.uniq, currentBoringness + 1
  end
end

# MAIN #

# setup debug log
Log = open "aggress-v1-log.txt", "w"
def log v
  Log.write v
  Log.write "\n"
  Log.flush
end

$:.unshift File.dirname($0)
require 'ants.rb'
ai = AI.new
ai.setup{}
ai.run do |ai| # this block is executed once for each turn
  log "TURN #{ai.turn_number}"
  
  # mark successfully visitted squares as visitted
  ai.map.each do |row|
    row.each do |square|
      square.visited = true if square.ant? and square.ant.mine?
      square.boringnesses = {}
    end
  end

  # pathfind
  ai.calculateBoringnesses
  
  ai.my_ants.each do |ant|
    
    possibleMoves = CardinalDirections.reject{|dir| ant.square.neighbor(dir).unsafe?}
    
    log "possible moves: #{possibleMoves.join ', '}"

    # pick a best move
    if possibleMoves.size > 0
      best = possibleMoves.map{|dir| ant.square.neighbor(dir).rateBoringness}.min
      log "best(lowest) rating: #{best}"
      goodMoves = possibleMoves \
        .reject{|dir| ant.square.neighbor(dir).rateBoringness > (best + 0.1)}
      log "good moves: #{goodMoves.join ', '}"
      move = goodMoves.random
      # order the ant if a valid move exists
      log "move #{move}"
      if move
        ant.square.ant = nil
        ant.square.neighbor(move).ant = ant
        ant.order move
      end
    end
  end
end

