# Hardcoded starting position for now
FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

# Test repeat moves w/ en passant
# FEN = "6k1/8/8/8/6p1/8/5P2/6K1 w - - 0 1"
# FEN = "6k1/8/8/8/6p1/8/5PR1/6K1 w - - 0 1"

# FEN = "K/8/8/8/8/8/8/kq w KQkq - 0 1"
# FEN = "8/1Q2K3/p2B1n2/1k4Pp/8/1R3P2/3bP3/1N5q w - h6 0 1"

# Move disambiguation testing
# FEN = "8/3Q4/8/1Q3Q2/8/5Q2/5QQ1/Q7 w - - 0 1"
# FEN = "6k1/8/3n3n/8/8/8/8/1K6 b - - 0 1"

# Pawn promotion testing
# FEN = "2b5/PP1PPPpp/2P5/8/8/4p3/pppp1pPP/4N3 w - - 0 1"

# Fifty-move rule testing
# FEN = "6k1/3R4/2R5/8/8/8/2K5/8 w - - 99 1"

FEN_KEY_STR_TO_SYM = {
  "p" => :pawn,
  "n" => :knight,
  "b" => :bishop,
  "r" => :rook,
  "q" => :queen,
  "k" => :king,
}
FEN_KEY_SYM_TO_STR = {
  pawn: "p",
  knight: "n",
  bishop: "b",
  rook: "r",
  queen: "q",
  king: "k",
}

class ChessGame
  def load_fen(fen_string)
    fen = fen_string.split(" ")

    # Set the pieces on the board. x and y track which square we're looking at
    x, y = 0, 0
    # The FEN reads from top-to-bottom, we're filling in bottom-to-top so
    # we reverse it
    ranks = fen[0].split("/").reverse
    ranks.each do |rank|
      rank.chars.each do |c|
        # If it's a number, put empty squares
        if c == (n = c.to_i).to_s
          n.times do
            @board[x][y] = nil
            x += 1
          end

          next
        end

        # Otherwise, put a piece and advance to the next square
        color = c.upcase == c ? :white : :black
        @board[x][y] = Piece.new(color, FEN_KEY_STR_TO_SYM[c.downcase])
        x += 1
      end

      y += 1
      x = 0
    end

    # Whose turn is it?
    @color_to_move = { "w" => :white, "b" => :black }[fen[1]]

    # Notation need to begin with an ellipsis if
    # loading a new board with black to move
    @notation << ["..."] if @color_to_move == :black && @notation.empty?

    set_castling_availability(fen[2])

    # Set en passant target square
    @en_passant_target = fen[3] == "-" ? nil : notation_to_square(fen[3])

    # For fifty-move rule
    @halfmove_count = fen[4].to_i

    @move_count = fen[5].to_i
  end

  def get_fen
    fen = []

    # Position
    fen << get_position

    # Color to move
    fen << @color_to_move.to_s[0]

    # Castling availability
    ca = @white_can_castle_kingside ? "K" : ""
    ca += "Q" if @white_can_castle_queenside
    ca += "k" if @black_can_castle_kingside
    ca += "q" if @black_can_castle_queenside
    fen << (ca.empty? ? "-" : ca)

    # En passant target square
    fen << (@en_passant_target ? square_to_notation(@en_passant_target) : "-")

    # Halfmoves
    fen << @halfmove_count.to_s

    # Moves
    fen << @move_count.to_s

    fen.join(" ")
  end

  def get_position
    # Rotate the board so we can start at the top and read across
    board_deep_copy.transpose.reverse.map do |rank|
      empty = 0
      rank.map do |piece|
        if piece
          str = FEN_KEY_SYM_TO_STR[piece.type]
          out = (empty > 0 ? empty.to_s : "") +
                (piece.color == :white ? str.upcase : str)
          empty = 0
          out
        else
          empty += 1
          ""
        end
      end.tap { |r| r[-1] += empty.to_s if empty > 0 }.join
    end.join("/")
  end
end
