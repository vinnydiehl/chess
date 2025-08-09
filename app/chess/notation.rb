class ChessGame
  def notation_to_square(str)
    [str[0].ord - 97, str[1].to_i - 1]
  end
end
