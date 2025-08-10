class ChessGame
  def in_check?(color, board = @board)
    color_vision(OTHER_COLOR[color], board).any? do |x, y|
      square = board[x][y]
      square&.color == color && square.type == :king
    end
  end
end
