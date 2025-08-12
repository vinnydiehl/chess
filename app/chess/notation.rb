PIECE_NOTATION = {
  knight: "N",
  bishop: "B",
  rook: "R",
  queen: "Q",
  king: "K",
}

class ChessGame
  def notation_to_square(str)
    [str[0].ord - 97, str[1].to_i - 1]
  end

  def file_notation(x)
    (x + 97).chr
  end

  def square_to_notation(square)
    "#{file_notation(square[0])}#{square[1] + 1}"
  end

  def add_notation_line(str)
    @notation << "\n" unless @notation.empty?
    @notation << str
  end

  def update_notation(piece, origin, x, y, capture, promoted)
    opponent = OTHER_COLOR[piece.color]

    ox, oy = origin

    # Generate notation for the piece which has been moved
    piece_moved = ""
    if piece.type == :pawn
      # Pawn only has origin square notation if it has captured
      piece_moved += file_notation(origin[0]) if capture
    elsif piece.type == :king && (offset = x - ox).abs == 2
      # Castling
      add_notation_move(offset < 0 ? "0-0-0" : "0-0")
      return
    else
      piece_moved += PIECE_NOTATION[piece.type]
    end

    # Generate the entire notation for this particular move
    notation_segment =
      "#{piece_moved}#{capture ? "x" : ""}#{square_to_notation([x, y])}"
    notation_segment += "#" if checkmate?(opponent)

    # Pawn promotion. For now it's always a queen, but this will change.
    if piece.type == :pawn && promoted
      notation_segment += "Q"
    end

    # Check
    if in_check?(opponent)
      notation_segment += "+"
    end

    add_notation_move(notation_segment)

    # Mate
    if stalemate?(opponent)
      add_notation_line("½-½")
    elsif checkmate?(opponent)
      add_notation_line("#{piece.color == :white ? '1-0' : '0-1'}")
    end
  end

  def add_notation_move(str)
    if @color_to_move == :black
      add_notation_line("#{@move_count}. #{str}")
    else
      @notation += " #{str}"
    end
  end
end
