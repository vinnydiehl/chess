class ChessGame
  # Entry into @positions
  def position_entry
    [
      # 0: FEN
      get_fen,
      # 1: Legal moves for every piece on the board (for threefold repetition)
      @board.each_with_index.map do |file, trx|
        file.each_with_index.map { |p, try| p ? legal_moves(p, trx, try) : nil }
      end,
      # 2: Sound played for this move
      nil,
      # 3: Starting/finishing squares for the move before this one (for highlighting)
      @last_move_squares,
    ]
  end

  def set_current_position(n)
    return unless (0...@positions.size).include?(n)

    # Clear piece selection
    @piece_selected = false
    @piece_already_selected = false

    @current_position = n
    pos = @positions[n]

    set_fen(pos[0])
    play_sound(pos[2])
    @last_move_squares = pos[3]
  end

  def on_last_position?
    @current_position == @positions.size - 1
  end
end
