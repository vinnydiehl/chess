class ChessGame
  def set_castling_availability(ca)
    @white_can_castle_kingside = ca.include?("K")
    @white_can_castle_queenside = ca.include?("Q")
    @black_can_castle_kingside = ca.include?("k")
    @black_can_castle_queenside = ca.include?("q")
  end

  # Set query methods e.g. white_can_castle_kingside?
  COLORS.each do |color|
    [:kingside, :queenside].each do |side|
      define_method("#{color}_can_castle_#{side}?") do
        instance_variable_get("@#{color}_can_castle_#{side}")
      end
    end
  end
end
