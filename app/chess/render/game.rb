class ChessGame
  def render_game
    render_background
    render_board
    render_square_highlights
    render_pieces
    render_captures_and_material
    render_notation
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
    render_last_move_highlight if @last_move_squares

    unless @promotion || @result
      render_hover_highlight
      render_legal_highlights if @piece_selected
      render_vision_highlights
    end
  end

  def render_last_move_highlight
    @last_move_squares.each do |x, y|
      @primitives << {
        primitive_marker: :solid,
        x: @x_offset + x * @square_size, y: y * @square_size,
        w: @square_size, h: @square_size,
        **LAST_MOVE_HIGHLIGHT_COLOR,
      }
    end
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
    if (piece = @piece_held || @piece_selected)
      moves = legal_moves(piece, *@piece_original_pos)
      return unless moves

      # Highlight selected piece square
      @primitives << {
        primitive_marker: :solid,
        x: @x_offset + @x_orig * @square_size,
        y: @y_orig * @square_size,
        w: @square_size, h: @square_size,
        **SELECTED_PIECE_HIGHLIGHT_COLOR,
      }

      # Render markers
      moves.each do |x, y|
        if @board[x][y]
          @primitives << {
            x: @x_offset + x * @square_size, y: y * @square_size,
            w: @square_size, h: @square_size,
            path: "sprites/shapes/legal_move_capture.png",
            a: 100,
          }
        elsif piece.type == :pawn && [x, y] == @en_passant_target
          @primitives << {
            x: @x_offset + x * @square_size + @legal_center_offset,
            y: y * @square_size + @legal_center_offset,
            w: @legal_marker_size, h: @legal_marker_size,
            path: "sprites/shapes/legal_move_en_passant.png",
            a: 100,
          }
        else
          @primitives << {
            x: @x_offset + x * @square_size + @legal_center_offset,
            y: y * @square_size + @legal_center_offset,
            w: @legal_marker_size, h: @legal_marker_size,
            path: "sprites/shapes/legal_move_empty_square.png",
            a: 100,
          }
        end
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

  def render_piece(piece, x, y, size = @square_size)
    @primitives << {
      x: x, y: y,
      w: size, h: size,
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

  def render_captures_and_material
    COLORS.each do |color|
      x_offset = @captures_x_offset
      y_offset = color == :white ? 0 : @board_size - @capture_size

      @captures[color].sort_by { |p| PIECE_SORTING_VALUE[p.type] }
                      .each_with_index do |piece, i|
        x_offset += CAPTURE_OVERLAP[piece.type] unless i == 0
        render_piece(piece, x_offset, y_offset, @capture_size)
      end

      render_material(color, material_values, x_offset, y_offset)
    end
  end

  def render_material(color, material, x_offset, y_offset)
    opponent = OTHER_COLOR[color]
    if material[color] <= material[opponent]
      return
    end

    differential = material[color] - material[opponent]

    # Adjust left margin
    if @captures[color].empty?
      x_offset += BOARD_PADDING
    else
      x_offset += @capture_size
    end

    @primitives << {
      primitive_marker: :label,
      x: x_offset,
      y: y_offset,
      text: "+#{differential}",
      alignment_enum: 0,
      vertical_alignment_enum: 0,
      size_enum: 0,
      **TEXT_COLOR,
    }
  end

  def render_notation
    # Draw border
    unless @notation.empty?
      @primitives << {
        primitive_marker: :border,
        x: @notation_box.x - 1, y: @notation_box.y - 2,
        w: @notation_box.w + 4, h: @notation_box.h + 5,
        **NOTATION_BOX_BORDER_COLOR,
      }
    end

    notation = @notation.clone
    # If there's a result, we'll just throw it onto the end
    notation << @result if @result

    notation[@notation_box_position...(NOTATION_MOVES_HEIGHT + @notation_box_position)]
      .each_with_index do |line, turn_i|
      y = @notation_y_top - (NOTATION_ROW_HEIGHT * (turn_i + 1))

      # Draw row
      @primitives << {
        primitive_marker: :solid,
        x: @notation_box.x, y: y,
        w: @notation_box.w, h: NOTATION_ROW_HEIGHT,
        **(turn_i.even? ? NOTATION_DARK_COLOR : NOTATION_LIGHT_COLOR),
      }

      # Draw result
      if @result && line == @result
        @primitives << {
          primitive_marker: :label,
          x: @notation_box.x + (@notation_box.w / 2),
          y: y + NOTATION_ROW_HEIGHT / 4 - NOTATION_Y_PADDING,
          text: @result,
          alignment_enum: 1,
          vertical_alignment_enum: 0,
          size_enum: NOTATION_SIZE,
          **TEXT_COLOR,
        }

        return
      end

      # Draw move number
      @primitives << {
        primitive_marker: :label,
        x: @notation_box.x + NOTATION_MARGIN,
        y: y + NOTATION_ROW_HEIGHT / 4 - NOTATION_Y_PADDING,
        text: "#{turn_i + 1 + @notation_box_position}.",
        alignment_enum: 0,
        vertical_alignment_enum: 0,
        size_enum: NOTATION_SIZE,
        **TEXT_COLOR,
      }

      line.each_with_index do |move, move_i|
        # Draw move notation
        @primitives << {
          primitive_marker: :label,
          x: @notation_box.x +
             NOTATION_MOVE_NUM_PADDING + (move_i * @notation_box.w / 2.5),
          y: y + NOTATION_ROW_HEIGHT / 4 - NOTATION_Y_PADDING,
          text: move,
          alignment_enum: 0,
          vertical_alignment_enum: 0,
          size_enum: NOTATION_SIZE,
          **TEXT_COLOR,
        }
      end
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
