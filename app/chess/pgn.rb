# Portable Game Notation
# Specification: https://www.saremba.de/chessgml/standards/pgn/pgn-complete.htm

# Test PGN
# PGN = <<EOS
# [Event "F\\\\S Return Match"]
# [Site "Belgrade, \\"Serbia\\" JUG"]
# [Date "1992.11.04"]
# [Round "29"]
# %[White "Fischer, Robert J."]
# [Black "Spassky, Boris V."]
# [Result "1/2-1/2"]
# [WhiteElo "2400"]
# [BlackElo "2300"]
#
# 1.e4 e5 2.Nf3 Nc6 3.Bb5 {This opening is called the "Ruy Lopez".} 3...a6
# 4.Ba4 Nf6 5.0-0 Be7 6.Re1 b5 7.Bb3 d6 8.c3 O-O 9.h3 Nb8 10.d4 Nbd7
# 11.c4 c6 12.cxb5 axb5 13.Nc3 Bb7 14.Bg5 b4 ; Line comment "test"!!!
# 15.Nb1 h6 16.Bh4 c5 17.dxe5 $11
# Nxe4 18.Bxe7 Qxe7 19.exd6 Qf6 20.Nbd2 Nxd6 21.Nc4 Nxc4 22.Bxc4 Nb6
# 23.Ne5 Rae8 24.Bxf7+ Rxf7 25.Nxf7 Rxe1+!! 26.Qxe1 Kxf7 27.Qe3 Qg5 28.Qxg5
# hxg5 29.b3 Ke6 30.a3 Kd6? 31.axb4 cxb4 32.Ra5 Nd5 33.f3 Bc8 34.Kf2 Bf5
# 35.Ra7 g6 36.Ra6+ Kc5 37.Ke1 Nf4?! 38.g3 Nxh3 39.Kd2 Kb5 40.Rd6 Kc5 41.Ra6
# Nf2 42.g4 Bd3 43.Re6 1/2-1/2
# EOS.strip

ALPHA = (("A".."Z").to_a + ("a".."z").to_a).join("")
NUMERIC = ("0".."9").to_a.join("")
ALPHANUMERIC = ALPHA + NUMERIC
WHITESPACE = " \n\t"
SYMBOL = ALPHANUMERIC + "_+#=:-/!?"

NOTATION_STR_TO_SYM = {
  "N" => :knight,
  "B" => :bishop,
  "R" => :rook,
  "Q" => :queen,
  "K" => :king,
}

# Seven Tag Roster
# Ordered set of required tags, with default values
STR = [
  ["Event", "?"],
  ["Site", "?"],
  ["Date", "????.??.??"],
  ["Round", "?"],
  ["White", "?"],
  ["Black", "?"],
  ["Result", "*"],
]
STR_SYMBOLS = %w[Event Site Date Round White Black Result]

NAG_TRADITIONAL = {
  1 => "!",
  2 => "?",
  3 => "!!",
  4 => "??",
  5 => "!?",
  6 => "?!",
}
NAG_TRADITIONAL_SYMBOLS = NAG_TRADITIONAL.values

class PGNError < StandardError
end

class ChessGame
  def tokenize_pgn(str)
    # Remove lines escaped with a % at the beginning
    str = str.lines.reject { |line| line.start_with?("%") }.join

    tokens = []

    current = ""
    build = nil
    escaping = false

    str.each_char do |c|
      # If we're building a token, proceed as necessary
      if build
        case build
        when :string
          if escaping
            current << c
            escaping = false
          elsif c == "\\"
            escaping = true
          elsif c == '"'
            # End the token at the terminating "
            build = nil
            tokens << current
            current = ""
          else
            current << c
          end

          next
        when :commentary
          # End the token at the terminating }
          if c == "}"
            build = nil
            tokens << current.strip
            current = ""
            # The } is a token
            tokens << c
          else
            # Newline becomes a space
            current << c == "\n" ? " " : c
          end

          next
        when :line_commentary
          # End the token at the terminating newline
          if c == "\n"
            build = nil
            tokens << current.strip
            current = ""
          else
            current << c
          end

          next
        when :symbol
          if SYMBOL.include?(c)
            current << c
            next
          end

          # Otherwise the integer or symbol is over
          build = nil
          tokens << current
          current = ""
        when :nag
          if NUMERIC.include?(c)
            current << c
            next
          end

          # Otherwise the NAG is over
          build = nil
          tokens << current
          current = ""
        end
      end

      # Whitespace delimiter
      if WHITESPACE.include?(c)
        unless current.empty?
          tokens << current
          current = ""
        end

        next
      end

      # Self-terminating tokens
      if current.empty? && ".*[]()<>".include?(c)
        tokens << c
        next
      end

      if current.empty?
        if ALPHANUMERIC.include?(c)
          build = :symbol
          current << c
        elsif c == '"'
          build = :string
        elsif c == "{"
          build = :commentary
          tokens << c
        elsif c == ";"
          build = :line_commentary
          tokens << c
        elsif c == "$"
          build = :nag
          current << c
        else
          raise PGNError.new(
            "PGN: Invalid character encountered with empty `current`: #{c}"
          )
        end

        next
      end

      raise PGNError.new(
        "PGN: End of tokenization reached with populated `current`: #{current}"
      )
    end

    tokens << current unless current.empty?

    tokens
  end

  def import_pgn(str)
    reset_game

    tokens = tokenize_pgn(str)

    # Parse tag pairs
    while tokens[0] == "["
      tokens.shift
      symbol = tokens.shift
      @tags[symbol] = tokens.shift

      # There should only be 2 tokens inside the tag
      if tokens.shift != "]"
        raise PGNError.new("PGN: Invalid tag pair.")
      end
    end

    # Parse movetext
    until tokens.size == 1
      token = tokens.shift

      # The "-" check is to handle castling notated with 0-0 rather than O-O
      if NUMERIC.include?(token[0]) && token[1] != "-"
        if @move_count != token.to_i
          raise PGNError.new(
            "PGN: Invalid move number: #{token} (should be #{@move_count})"
          )
        end
      elsif token == "{"
        @positions[-1][:annotation] = tokens.shift
        unless tokens.shift == "}"
          raise PGNError.new("PGN: Annotation contains multiple tokens.")
        end
      elsif token == ";"
        @positions[-1][:annotation] = tokens.shift
      elsif token[0] == "$"
        @positions[-1][:nag] = token[1..].to_i
        next
      elsif token == "."
        next
      elsif ALPHA.include?(token[0]) || token[0..1] == "0-"
        # We've encountered a move

        # Process traditional NAG annotation (!, ?, etc.)
        nag = nil
        symbol_size = nil
        NAG_TRADITIONAL_SYMBOLS.each_with_index do |symbol, i|
          if token.end_with?(symbol)
            nag = i + 1
            symbol_size = symbol.size
          end
        end
        if symbol_size
          token = token[0...-(symbol_size)]
        end

        # Fix improper castling notation (it should be O not 0)
        if token == "0-0"
          token = "O-O"
        elsif token == "0-0-0"
          token = "O-O-O"
        end

        if @notation[-1]&.size == 1
          # Black's move
          @notation[-1] << token
        else
          # White's move
          @notation << [token]
        end

        add_move_to_positions(parse_move_notation(token, nag))
      else
        raise PGNError.new("PGN: Invalid token in movetext: #{token}")
      end
    end

    # If last token is "*" game is still in progress, otherwise
    # that's the result
    unless ["*", "1-0", "0-1", "1/2-1/2"].include?(tokens[0])
      raise PGNError.new("PGN: Invalid result.")
    end
    @result = tokens[0] == "*" ? nil : tokens[0]
    # Prettify draw result
    @result = "½-½" if @result == "1/2-1/2"

    # If there's a result, need to set the sound for the last positionruby flap map
    @positions[-1][:sound] = :game_end if @result

    # We've been using @board to load the PGN, so set the position to
    # the starting position
    set_current_position(0)
  end

  def parse_move_notation(str, nag)
    original_str = str
    color = @color_to_move

    # Castling is a special case, handle it right away
    if ["0-0", "O-O"].include?(str.upcase)
      return { san: "O-O", color: color, castle: :kingside, nag: nag }
    elsif ["0-0-0", "O-O-O"].include?(str.upcase)
      return { san: "O-O-O", color: color, castle: :queenside, nag: nag }
    end

    # Clone the input so we don't destroy it
    str = str.clone

    # If it's a capture, record that fact and remove the x
    capture = str.include?("x")
    str.gsub!("x", "") if capture

    # Check/checkmate
    check, checkmate = false, false
    if str[-1] == "+"
      check = true
      str.chop!
    elsif str[-1] == "#"
      checkmate = true
      str.chop!
    end

    # Determine piece type
    type = :pawn
    if str[0] == str[0].upcase
      type = NOTATION_STR_TO_SYM[str[0]]
      str.slice!(0)
    end

    # Pawn promotion
    promotion = nil
    if type == :pawn
      # Handle notation like e8(Q)
      str.chop! if str[-1] == ")"

      if ALPHA.include?(str[-1])
        promotion = NOTATION_STR_TO_SYM[str[-1].upcase]
        str.chop!
        # There might be leading symbol, remove it
        str.chop! if "=/(".include?(str[-1])
      end
    end

    # Target square
    square = notation_to_square(str.slice!(-2, 2))

    # All that's left should be move disambiguation, if anything
    disambiguation_x, disambiguation_y = nil, nil
    until str.empty?
      c = str.slice!(0)
      if ALPHA.include?(c)
        disambiguation_y = file_notation_to_square(c)
      elsif NUMERIC.include?(c)
        disambiguation_x = rank_notation_to_square(c)
      end
    end

    {
      san: original_str,
      color: color,
      type: type,
      square: square,
      capture: capture,
      disambiguation_x: disambiguation_x,
      disambiguation_y: disambiguation_y,
      promotion: promotion,
      check: check,
      checkmate: checkmate,
      nag: nag,
    }
  end

  # Takes a Hash `move` containing all of the data that can be gleaned
  # from the move notation, and inserts an entry into @positions.
  #
  # `move` contains the following keys:
  #  * san
  #  * color
  #  * type
  #  * square
  #  * capture
  #  * disambiguation_x
  #  * disambiguation_y
  #  * promotion
  #  * check
  #  * checkmate
  #  * nag
  def add_move_to_positions(move)
    # Handle castling right away
    if (castle = move[:castle])
      y = move[:color] == :white ? 0 : 7
      rook_x = castle == :kingside ? 7 : 0
      king_target_x = castle == :kingside ? 6 : 2
      rook_target_x = castle == :kingside ? 5 : 3

      @last_move_squares = [[4, y], [king_target_x, y]]

      # Move king
      @board[4][y] = nil
      @board[king_target_x][y] = Piece.new(move[:color], :king)
      # Move rook
      @board[rook_x][y] = nil
      @board[rook_target_x][y] = Piece.new(move[:color], :rook)

      # No more castling
      instance_variable_set("@#{move[:color]}_can_castle_kingside", false)
      instance_variable_set("@#{move[:color]}_can_castle_queenside", false)

      @color_to_move = OTHER_COLOR[@color_to_move]
      # Increment move counters
      @move_count += 1 if move[:color] == :black
      @halfmove_count += 1
      @halfmove_total += 1

      @positions << position_entry(sound: :castle, nag: move[:nag])

      return
    end

    @board.each_with_index do |file, x|
      next if move[:disambiguation_y] && move[:disambiguation_y] != x

      file.each_with_index do |piece, y|
        next if move[:disambiguation_x] && move[:disambiguation_x] != y

        # Filtering for piece of the proper color and type
        next if piece&.color != move[:color] || piece&.type != move[:type]

        # If we've reached this point, we've found a hopefully properly
        # disambiguated piece to move, so check if the piece can legally
        # move there
        tx, ty = move[:square][0], move[:square][1]
        next unless legal_moves(piece, x, y).include?([tx, ty])

        # Record capture (will be nil if there's nothing there)
        capture = @board[tx][ty]

        @board[x][y] = nil
        @board[tx][ty] = piece
        @last_move_squares = [[x, y], [tx, ty]]

        # Castling availability
        if piece.type == :king
          # Moving the king means no more castling for that color
          instance_variable_set("@#{move[:color]}_can_castle_kingside", false)
          instance_variable_set("@#{move[:color]}_can_castle_queenside", false)
        end
        if piece.type == :rook && [0, 7].include?(x)
          side_affected = { 0 => :queenside, 7 => :kingside }[x]
          instance_variable_set("@#{move[:color]}_can_castle_#{side_affected}", false)
        end

        if piece.type == :pawn
          # En passant
          ep_y = piece.color == :white ? ty - 1 : ty + 1

          # Set en passant target
          if (y - ty).abs == 2
            @en_passant_target = [tx, ep_y]
          else
            # Capture
            if [tx, ty] == @en_passant_target
              capture = @board[tx][ep_y]
              @board[tx][ep_y] = nil
            end

            @en_passant_target = nil
          end

          # Pawn promotion
          if move[:promotion]
            @board[tx][ty] = Piece.new(move[:color], move[:promotion])
          end
        else
          @en_passant_target = nil
        end

        @captures[move[:color]] << capture if capture

        # Set appropriate sound (ordered for precedence)
        sound = capture ? :capture : :move_self
        sound = :promotion if move[:promotion]
        sound = :move_check if move[:check]

        @color_to_move = OTHER_COLOR[@color_to_move]
        # Increment move counters
        @move_count += 1 if move[:color] == :black
        if move[:type] != :pawn && !move[:capture]
          @halfmove_count += 1
        else
          @halfmove_count = 0
        end
        @halfmove_total += 1

        @positions << position_entry(sound: sound, nag: move[:nag])

        return
      end
    end

    dots = @color_to_move == :white ? "." : "..."
    raise PGNError.new("Unable to make move: #{@move_count}#{dots} #{move[:san]}")
  end

  def export_pgn
    # Seven Tag Roster is required in order even if the values aren't set
    pgn = STR.map do |symbol, default|
      "[#{symbol} #{pgn_string(@tags[symbol] || default)}]\n"
    end.join
    # Then add any other tags
    pgn << @tags.map do |symbol, value|
      unless STR_SYMBOLS.include?(symbol)
        "[#{symbol} #{pgn_string(value)}]\n"
      else
        nil
      end
    end.compact.join
    pgn << "\n"

    # Movetext
    movetext = @positions[1..].map.with_index do |position, i|
      color = position[:fen].split(" ")[1] == "b" ? :white : :black
      move_num = color == :white ? "#{halfmove_to_move(i + 1)}." : ""

      nag = ""
      if (1..6).include?(position[:nag])
        nag = NAG_TRADITIONAL[position[:nag]]
      elsif (position[:nag] || 0) > 6
        nag = " $#{position[:nag]}"
      end

      annotation = position[:annotation] ? " {#{position[:annotation]}}" : ""

      "#{move_num}#{@notation.flatten[i]}#{nag}#{annotation}"
    end.join(" ")

    # Add result to movetext
    movetext << " " + if @result
      @result == "½-½" ? "1/2-1/2" : @result
    else
      "*"
    end

    pgn << soft_wrap(movetext)

    pgn
  end

  def pgn_string(str)
    "\"#{str.gsub('"', '\\"')}\""
  end

  # Word wraps a string at spaces
  def soft_wrap(str, width = 80)
    str.split.each_with_object([""]) do |word, lines|
      lines[-1] += (lines[-1].empty? ? "" : " ") + word
      lines << "" if lines[-1].length >= width
    end.reject(&:empty?).join("\n")
  end
end
