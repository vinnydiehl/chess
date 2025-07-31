class ChessGame
  def render_game
    render_background
    render_board
    render_square_highlights
    render_pieces
  end

  def render_board
    @primitives << {
      primitive_marker: :solid,
      x: @x_offset, y: 0,
      w: @board_size, h: @board_size,
      **LIGHT_SQUARE_COLOR
    }

    [0, 2, 4, 6].each do |rank|
      [1, 3, 5, 7].each do |file|
        @primitives << {
          primitive_marker: :solid,
          x: @x_offset + @square_size * (file - 1), y: @square_size * rank,
          w: @square_size, h: @square_size,
          **DARK_SQUARE_COLOR
        }
      end
    end

    [1, 3, 5, 7].each do |rank|
      [2, 4, 6, 8].each do |file|
        @primitives << {
          primitive_marker: :solid,
          x: @x_offset + @square_size * (file - 1), y: @square_size * rank,
          w: @square_size, h: @square_size,
          **DARK_SQUARE_COLOR
        }
      end
    end
  end

  def render_square_highlights
    render_hover_highlight
    render_legal_highlights
  end

  def render_hover_highlight
    # Highlight square under cursor, unless a piece is picked up, then leave
    # the highlight on the piece's original position
    if mouse_on_board? || @piece_held
      if @piece_held
        x, y = @piece_original_pos
      else
        x, y = mouse_board_pos
      end

      @primitives << {
        primitive_marker: :solid,
        x: @x_offset + x * @square_size, y: y * @square_size,
        w: @square_size, h: @square_size,
        **HOVER_HIGHLIGHT_COLOR
      }
    end
  end

  def render_legal_highlights
    if @piece_held
      moves = legal_moves(@piece_held, *@piece_original_pos)
      return unless moves
      moves.each do |move|
        x, y = move
        @primitives << {
          primitive_marker: :solid,
          x: @x_offset + x * @square_size, y: y * @square_size,
          w: @square_size, h: @square_size,
          **LEGAL_MOVE_HIGHLIGHT_COLOR
        }
      end
    end
  end

  def render_pieces
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

    if @piece_held
      offset = @square_size / 2

      @primitives << {
        x: @mouse.x - offset, y: @mouse.y - offset,
        w: @square_size, h: @square_size,
        path: @piece_held.sprite_path
      }
    end
  end
end
