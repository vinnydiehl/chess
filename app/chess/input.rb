class ChessGame
  def mouse_board_pos
    x, y = true_square([
      ((@mouse.x - @x_offset) / @square_size).floor,
      (@mouse.y / @square_size).floor
    ])

    [x, y].all? { |n| (0..7).include? n } ? [x, y] : nil
  end

  def mouse_on_board?
    !mouse_board_pos.nil?
  end

  # Returns the x square position (0-3) of the mouse within the
  # pawn promotion picker
  def mouse_picker_pos
    return unless @mouse.intersect_rect?(@promotion_picker_rect)
    ((@mouse.x - @promotion_picker_rect.x) / @square_size).floor
  end

  def mouse_in_notation_box?
    @mouse.intersect_rect?(@notation_box)
  end

  # I'm adding this, but not all mouse inputs are included here.
  # Maybe needs a refactor...
  def process_mouse_inputs
    if mouse_in_notation_box?
      if (direction = @mouse.wheel&.y)
        scroll = direction > 0 ? :up : :down
        case scroll
        when :up
          @notation_box_position -= 1 if @notation_box_position > 0
        when :down
          if @notation_box_position < notation_box_row_count - NOTATION_MOVES_HEIGHT
            @notation_box_position += 1
          end
        end
      end

      if @mouse.key_down.left && (halfmove = mouse_pos_to_halfmove)
        set_current_position(halfmove)
      end

      if @mouse.key_down.right && (halfmove = mouse_pos_to_halfmove)
        set_current_position(halfmove)
        @position_editing = @positions[halfmove]
        init_position_editor
      end
    end
  end

  # There are some rendering inputs which aren't included in this
  # Maybe needs a refactor...
  # Noticing a trend here?
  def process_keyboard_inputs
    if @position_editing
      if @kb.key_down?(:enter)
        save_position
      end

      if @kb.key_down?(:escape)
        @position_editing = nil
      end
    else
      if @kb.key_down?(:f)
        set_scene(:fen_menu)
      end

      if @kb.key_down?(:p)
        set_scene(:pgn_menu)
      end

      if @kb.key_down?(:n)
        print_notation
      end

      if @kb.key_down?(:space)
        @color_view = OTHER_COLOR[@color_view]
      end
    end

    if @kb.key_down?(:right)
      set_current_position(@current_position + 1)
    end

    if @kb.key_down?(:left)
      set_current_position(@current_position - 1)
    end
  end
end
