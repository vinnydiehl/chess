class ChessGame
  def game_init
    @x_offset = @screen_width / 4
    @board_size = @screen_height # for now
    @square_size = @board_size / 8

    @board = @state.board
    @board = Array.new(8) { Array.new(8, nil) }
  end

  def game_tick; end
end
