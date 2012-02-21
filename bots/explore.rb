=begin
  This ants bot tries to move into unvisited spaces.
  
  Sam Auciello, Isaac Dupree | Marlboro College
  Jan-Feb 2012               | opensource.org/licenses/MIT
=end

# CONSTANTS #

Infinity = 1.0 / 0.0

# METHODS #

class Array
  def random
    if self.size == 0 then nil else self[rand self.size] end
  end
end

class Square
  # A square is "visited" if one of our ants have ever been in it.
  attr_accessor :visited
  attr_writer :boringness

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
  def neighbors
    [:N, :S, :E, :W].map{|dir| self.neighbor dir}
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

class AI
  def unexploredSquares
    @map.flatten(1).reject{|square| not square.interesting?}
  end
  # frontier is an array!
  def calculateBoringness frontier=self.unexploredSquares, currentBoringness=0
    ""
    log "currentBoringness = #{currentBoringness}, |frontier| = #{frontier.size}"
    
    return if frontier.size == 0
    
    newFrontier = []
    
    frontier.each do |square|
      if square.boringness == nil and not square.water?
        square.boringness = currentBoringness
        
        # is this filter more efficient before or after the loop?
        relevantNeighbors = square.neighbors.reject do |neighbor|
          neighbor.boringness != nil or neighbor.water?
        end
        
        newFrontier.push *relevantNeighbors
      end
    end
    calculateBoringness newFrontier.uniq, currentBoringness + 1
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

$:.unshift File.dirname($0)
require 'ants.rb'
ai = AI.new
ai.setup{}
ai.run do |ai| # this block is executed once for each turn
  
  # mark successfully visitted squares as visitted
  ai.map.each do |row|
    row.each do |square|
      square.boringness = nil
      square.visited = true if square.ant? and square.ant.mine?
      square.boringness = nil
    end
  end

  # calculate boringness
  ai.calculateBoringness
  
  ai.my_ants.each do |ant|
    
    log "eliminate squares from which interesting squares cannot be reached"
    # eliminate squares from which interesting squares cannot be reached
    possibleMoves = [:N, :E, :S, :W].reject do |dir|
      square = ant.square.neighbor(dir)
      square.unsafe? or square.boringness == nil
    end
    
    log "possible moves: #{possibleMoves.join ', '}"
    
    log "pick best move"
    # pick a best move
    if possibleMoves.size > 0
      best = possibleMoves.map{|dir| ant.square.neighbor(dir).boringness}.min
      move = possibleMoves \
        .reject{|dir| ant.square.neighbor(dir).boringness != best} \
        .random
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

