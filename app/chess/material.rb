class ChessGame
  def material_values
    board = @board.flatten

    COLORS.map do |color|
      m = board.sum { |p| p&.color == color ? PIECE_VALUE[p.type] : 0 }

      # If there's a piece held, it's not part of the board, but
      # it's still yours so include it
      if @piece_held&.color == color
        m += PIECE_VALUE[@piece_held.type]
      end

      [color, m]
    end.to_h
  end
end
