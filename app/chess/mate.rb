class ChessGame
  def no_legal_moves?(color)
    @board.each_with_index.flat_map do |file, x|
      file.each_with_index.flat_map do |piece, y|
        piece&.color == color ? (legal_moves(piece, x, y) || []) : []
      end
    end.empty?
  end

  def checkmate?(color_to_move)
    no_legal_moves?(color_to_move) && in_check?(color_to_move)
  end

  def stalemate?(color_to_move)
    no_legal_moves?(color_to_move) && !in_check?(color_to_move)
  end
end
