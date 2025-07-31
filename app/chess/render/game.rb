class ChessGame
  def render_game
    render_background
    render_board
    render_pieces
  end

  def render_board
    dark_color = { r: 118, g: 150, b: 86 }
    light_color = { r: 238, g: 238, b: 210 }

    @primitives << {
      primitive_marker: :solid,
      x: @x_offset, y: 0,
      w: @board_size, h: @board_size,
      **light_color
    }

    [0, 2, 4, 6].each do |rank|
      [1, 3, 5, 7].each do |file|
        @primitives << {
          primitive_marker: :solid,
          x: @x_offset + @square_size * (file - 1), y: @square_size * rank,
          w: @square_size, h: @square_size,
          **dark_color
        }
      end
    end

    [1, 3, 5, 7].each do |rank|
      [2, 4, 6, 8].each do |file|
        @primitives << {
          primitive_marker: :solid,
          x: @x_offset + @square_size * (file - 1), y: @square_size * rank,
          w: @square_size, h: @square_size,
          **dark_color
        }
      end
    end
  end

  def render_pieces
    @board[0][0] = Piece.new(:black, :rook)
    @board[1][1] = Piece.new(:white, :king)

    @board.each_with_index do |pieces, file|
      pieces.each_with_index do |piece, rank|
        if piece
          @primitives << {
            x: @x_offset + file * @square_size, y: rank * @square_size,
            w: @square_size, h: @square_size,
            path: piece.sprite_path
          }
        end
      end
    end
  end
end
