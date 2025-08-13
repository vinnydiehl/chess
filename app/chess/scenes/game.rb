class ChessGame
  def game_init
    @x_offset = @screen_width / 4
    @board_size = @screen_height # for now
    @square_size = @board_size / 8

    @board = Array.new(8) { Array.new(8, nil) }
    @notation = ""

    @piece_held = nil
    @piece_original_pos = nil

    @x_orig, @y_orig = 0, 0

    set_fen(FEN)
  end

  def game_tick
    resolve_move_input
  end

  def board_deep_copy(board = @board)
    temp = []

    board.each do |file|
      tf = []
      file.each { |piece| tf << piece }
      temp << tf
    end

    temp
  end
end
