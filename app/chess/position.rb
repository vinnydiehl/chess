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

    load_fen(pos[0])
    play_sound(pos[2])
    @last_move_squares = pos[3]

    # Scroll notation box if the selected move goes outside of it
    move = halfmove_to_move(n)
    if move > NOTATION_MOVES_HEIGHT + @notation_box_position
      @notation_box_position = move - NOTATION_MOVES_HEIGHT
    elsif move <= @notation_box_position && @notation_box_position > 0
      @notation_box_position = move - 1
    end

    # If the game has resolved and we advance to the last move,
    # scroll to show the result
    if @result && @current_position == @positions.size - 1
      @notation_box_position = [
        0,
        halfmove_to_move(@current_position) + 1 - NOTATION_MOVES_HEIGHT,
      ].max
    end
  end

  def on_last_position?
    @current_position == @positions.size - 1
  end

  def halfmove_to_move(n)
    ((n + 1) / 2).floor
  end
end
