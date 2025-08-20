# These methods deal with flipping the color between white and black.

class ChessGame
  def rotate_180(matrix)
    matrix.reverse.map(&:reverse)
  end

  # Indexes of the board matrix, x or y, are 0-7. When viewing as white,
  # this is the true index, but if viewing as black, 0 becomes 7,
  # 1 becomes 6, and so on.
  def true_index(n)
    @color_view == :white ? n : 7 - n
  end

  # Given a square coordinate as displayed on the screen, return the
  # actual coordinate on the board (it's flipped if we're viewing as black)
  def true_square(square)
    square.map { |n| true_index(n) }
  end
end
