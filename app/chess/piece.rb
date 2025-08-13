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

class ChessGame
  # Returns an array of squares that the piece on [sx, sy] can legally move to,
  # or nil if there are no legal moves.
  def legal_moves(piece, sx, sy, board = @board, color_to_move = @color_to_move)
    # If it's not your turn, fuck you
    return if piece.color != color_to_move

    moves = piece_vision(piece, sx, sy, board).reject do |x, y|
      # Simulate all possible moves for the piece and reject moves that would
      # put the player in check
      temp_board = board_deep_copy(board)
      temp_board[sx][sy] = nil
      temp_board[x][y] = piece
      in_check?(piece.color, temp_board)
    end

    # Castling legality
    if piece.type == :king
      opponent_vision = color_vision(OTHER_COLOR[piece.color])

      if send("#{piece.color}_can_castle_kingside?") &&
         (1..2).all? { |n| sx + n <= 7 && board[sx + n][sy].nil? } &&
         (sx..sx + 1).none? { |x| opponent_vision.include?([x, sy]) }
        moves << [sx + 2, sy]
      end

      if send("#{piece.color}_can_castle_queenside?") &&
         (1..3).all? { |n| sx - n >= 0 && board[sx -n][sy].nil? } &&
         (sx - 2..sx).none? { |x| opponent_vision.include?([x, sy]) }
        moves << [sx - 2, sy]
      end
    end

    moves
  end
end
