class ChessGame
  # Entry into @positions
  def position_entry(sound: nil, nag: nil)
    {
      # FEN
      fen: get_fen,
      # Legal moves for every piece on the board (for threefold repetition)
      legal_moves: @board.each_with_index.map do |file, trx|
        file.each_with_index.map { |p, try| p ? legal_moves(p, trx, try) : nil }
      end,
      # Sound played for this move
      sound: sound,
      # Starting/finishing squares for the move before this one (for highlighting)
      last_move: @last_move_squares,
      captures: hash_deep_copy(@captures),
      annotation: nil,
      nag: nag,
    }
  end

  def set_current_position(n)
    return unless (0...@positions.size).include?(n)

    # Clear piece selection
    @piece_selected = false
    @piece_already_selected = false

    @current_position = n
    pos = @positions[n]

    load_fen(pos[:fen])
    play_sound(pos[:sound])
    @last_move_squares = pos[:last_move]
    @captures = pos[:captures]

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
