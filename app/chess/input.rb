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
end
