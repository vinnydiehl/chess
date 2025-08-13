class ChessGame
  def render_game
    render_background
    render_board
    render_square_highlights unless @promotion
    render_pieces
    render_promotion_picker if @promotion
  end

  def render_board
    @primitives << {
      primitive_marker: :solid,
      x: @x_offset, y: 0,
      w: @board_size, h: @board_size,
      **LIGHT_SQUARE_COLOR,
    }

    [0, 2, 4, 6].each do |rank|
      [1, 3, 5, 7].each do |file|
        @primitives << {
          primitive_marker: :solid,
          x: @x_offset + @square_size * (file - 1), y: @square_size * rank,
          w: @square_size, h: @square_size,
          **DARK_SQUARE_COLOR,
        }
      end
    end

    [1, 3, 5, 7].each do |rank|
      [2, 4, 6, 8].each do |file|
        @primitives << {
          primitive_marker: :solid,
          x: @x_offset + @square_size * (file - 1), y: @square_size * rank,
          w: @square_size, h: @square_size,
          **DARK_SQUARE_COLOR,
        }
      end
    end
  end

  def render_square_highlights
    render_hover_highlight
    render_legal_highlights
    render_vision_highlights
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
        **HOVER_HIGHLIGHT_COLOR,
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
          **LEGAL_MOVE_HIGHLIGHT_COLOR,
        }
      end
    end
  end

  # Debug function to show what pieces each side has vision on
  def render_vision_highlights
    { w: :white, b: :black }.each do |key, color|
      if @kb.key_down_or_held?(key)
        vision = color_vision(color)
        return unless vision
        vision.each do |square|
          x, y = square
          @primitives << {
            primitive_marker: :solid,
            x: @x_offset + x * @square_size, y: y * @square_size,
            w: @square_size, h: @square_size,
            **LEGAL_MOVE_HIGHLIGHT_COLOR,
          }
        end
      end
    end
  end

  def render_piece(piece, x, y)
    @primitives << {
      x: x, y: y,
      w: @square_size, h: @square_size,
      path: piece.sprite_path,
    }
  end

  def render_pieces
    @board.each_with_index do |pieces, file|
      pieces.each_with_index do |piece, rank|
        if piece
          render_piece(piece, @x_offset + file * @square_size, rank * @square_size)
        end
      end
    end

    if @piece_held
      offset = @square_size / 2
      render_piece(@piece_held, @mouse.x - offset, @mouse.y - offset)
    end
  end

  def render_promotion_picker
    # Render picker background
    w, h = @square_size * 4, @square_size
    border_thickness = 5
    @primitives << {
      primitive_marker: :solid,
      x: @promotion_picker_rect[:x] - (border_thickness * 2),
      y: @promotion_picker_rect[:y] - (border_thickness * 2),
      w: w + (border_thickness * 4), h: h + (border_thickness * 4),
      r: 100, g: 100, b: 100,
    }
    @primitives << {
      primitive_marker: :solid,
      x: @promotion_picker_rect[:x] - border_thickness,
      y: @promotion_picker_rect[:y] - border_thickness,
      w: w + (border_thickness * 2), h: h + (border_thickness * 2),
      **LIGHT_SQUARE_COLOR,
    }
    @primitives << {
      primitive_marker: :solid,
      **@promotion_picker_rect,
      **DARK_SQUARE_COLOR, a: 150,
    }

    # Render hover highlight
    if mouse_pos = mouse_picker_pos
      @primitives << {
        primitive_marker: :solid,
        x: @promotion_picker_rect.x + (mouse_pos * @square_size),
        y: @promotion_picker_rect.y,
        w: @square_size, h: @square_size,
        **HOVER_HIGHLIGHT_COLOR,
      }
    end

    # Render pieces
    PROMOTION_PIECES.each_with_index do |type, i|
      piece = Piece.new(OTHER_COLOR[@color_to_move], type)
      render_piece(
        piece,
        @promotion_picker_rect[:x] + (i * @square_size),
        @promotion_picker_rect[:y]
      )
    end
  end
end
