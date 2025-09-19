class ChessGame
  # Returns a Piece according to the mouse's position on the
  # board editor, or nil if the mouse isn't over the editor.
  def board_editor_mouse_piece
    return unless @editing_board && @mouse.intersect_rect?(@board_editor_rect)

    # Relative x and y values
    x = @mouse.x - @board_editor_rect.x
    y = @mouse.y - @board_editor_rect.y

    color = [:white, :black][(x / @square_size).floor]
    type = BOARD_EDITOR_PIECES[(y / @square_size).floor]

    Piece.new(color, type)
  end
end
