class ChessGame
  def game_init
    @x_offset = @screen_width / 4
    @board_size = @screen_height # for now
    @square_size = @board_size / 8

    @board = Array.new(8) { Array.new(8, nil) }

    @piece_held = nil
    @piece_original_pos = nil

    set_fen(FEN)
  end

  def game_tick
    if mouse_on_board?
      if @mouse.key_down.left
        x, y = mouse_board_pos
        return if (@board[x][y].nil?)
        @piece_held = @board[x][y]
        @piece_original_pos = [x, y]
        @board[x][y] = nil
      end
    end

    if @piece_held && @mouse.key_up.left
      if mouse_on_board?
        x, y = mouse_board_pos
        @board[x][y] = @piece_held
        @piece_held = nil
        @piece_original_pos = nil
      else
        @board[@piece_original_pos.x][@piece_original_pos.y] = @piece_held
        @piece_held = nil
        @piece_original_pos = nil
      end
    end
  end
end
