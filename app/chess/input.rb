class ChessGame
  def mouse_board_pos
    x, y = [
      ((@mouse.x - @x_offset) / @square_size).floor,
      (@mouse.y / @square_size).floor
    ]

    [x, y].all? { |n| (0..7).include? n } ? [x, y] : nil
  end

  def mouse_on_board?
    !mouse_board_pos.nil?
  end

  # Returns the x square position (0-3) of the mouse within the
  # pawn promotion picker
  def mouse_picker_pos
    return unless @mouse.intersect_rect?(@promotion_picker_rect)
    ((@mouse.x - @promotion_picker_rect.x) / @square_size).floor
  end
end
