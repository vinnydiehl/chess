CODES = {
  pawn: "p",
  bishop: "b",
  knight: "n",
  rook: "r",
  queen: "q",
  king: "k"
}

class Piece
  attr_reader :color, :type

  def initialize(color, type)
    @color, @type = color, type
  end

  def code
    CODES[@type]
  end

  def sprite_path
    "sprites/pieces/#{@color.to_s[0]}#{code}.png"
  end
end
