# Hardcoded starting position for now
FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

# FEN = "K/8/8/8/8/8/8/kq w KQkq - 0 1"
# FEN = "8/1Q2K3/p2B1n2/1k4Pp/8/1R3P2/3bP3/1N5q w - h6 0 1"

# Move disambiguation testing
# FEN = "8/3Q4/8/1Q3Q2/8/5Q2/5QQ1/Q7 w - - 0 1"
# FEN = "8/8/3n3n/8/8/8/8/8 b - - 0 1"

# Pawn promotion testing
# FEN = "2b5/PP1PPPpp/2P5/8/8/4p3/pppp1pPP/4N3 w - - 0 1"

# Fifty-move rule testing
# FEN = "6k1/3R4/2R5/8/8/8/2K5/8 w - - 99 1"

KEY = {
  "p" => :pawn,
  "b" => :bishop,
  "n" => :knight,
  "r" => :rook,
  "q" => :queen,
  "k" => :king
}

class ChessGame
  def set_fen(fen_string)
    fen = fen_string.split(" ")

    # Set the pieces on the board. x and y track which square we're looking at
    x, y = 0, 0
    # The FEN reads from top-to-bottom, we're filling in bottom-to-top so
    # we reverse it
    ranks = fen[0].split("/").reverse
    ranks.each do |rank|
      rank.chars.each do |c|
        # If it's a number, put empty squares
        if c == c.to_i.to_s
          x += c.to_i
          next
        end

        # Otherwise, put a piece and advance to the next square
        color = c.upcase == c ? :white : :black
        @board[x][y] = Piece.new(color, KEY[c.downcase])
        x += 1
      end

      y += 1
      x = 0
    end

    # Whose turn is it?
    @color_to_move = { "w" => :white, "b" => :black }[fen[1]]

    set_castling_availability(fen[2])

    # Set en passant target square
    @en_passant_target = fen[3] == "-" ? nil : notation_to_square(fen[3])

    # For fifty-move rule
    @halfmove_count = fen[4].to_i

    @move_count = fen[5].to_i
  end
end
