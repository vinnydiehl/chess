# Portable Game Notation
# Specification: https://www.saremba.de/chessgml/standards/pgn/pgn-complete.htm

# Test PGN
PGN = <<EOS
[Event "F\\\\S Return Match"]
[Site "Belgrade, \\"Serbia\\" JUG"]
[Date "1992.11.04"]
[Round "29"]
[White "Fischer, Robert J."]
[Black "Spassky, Boris V."]
[Result "1/2-1/2"]

1.e4 e5 2.Nf3 Nc6 3.Bb5 {This opening is called the "Ruy Lopez".} 3...a6
4.Ba4 Nf6 5.0-0 Be7 6.Re1 b5 7.Bb3 d6 8.c3 O-O 9.h3 Nb8 10.d4 Nbd7
11.c4 c6 12.cxb5 axb5 13.Nc3 Bb7 14.Bg5 b4 ; Line comment "test"!!!
15.Nb1 h6 16.Bh4 c5 17.dxe5 $242
Nxe4 18.Bxe7 Qxe7 19.exd6 Qf6 20.Nbd2 Nxd6 21.Nc4 Nxc4 22.Bxc4 Nb6
23.Ne5 Rae8 24.Bxf7+ Rxf7 25.Nxf7 Rxe1+ 26.Qxe1 Kxf7 27.Qe3 Qg5 28.Qxg5
hxg5 29.b3 Ke6 30.a3 Kd6 31.axb4 cxb4 32.Ra5 Nd5 33.f3 Bc8 34.Kf2 Bf5
35.Ra7 g6 36.Ra6+ Kc5 37.Ke1 Nf4 38.g3 Nxh3 39.Kd2 Kb5 40.Rd6 Kc5 41.Ra6
Nf2 42.g4 Bd3 43.Re6 1/2-1/2
EOS

ALPHA = (("A".."Z").to_a + ("a".."z").to_a).join("")
NUMERIC = ("0".."9").to_a.join("")
ALPHANUMERIC = ALPHA + NUMERIC
WHITESPACE = " \n\t"
SYMBOL = ALPHANUMERIC + "_+#=:-/"

NOTATION_STR_TO_SYM = {
  "N" => :knight,
  "B" => :bishop,
  "R" => :rook,
  "Q" => :queen,
  "K" => :king,
}

class PGNError < StandardError
end

class ChessGame
  def tokenize_pgn(str)
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
          # For testing
          # The code shouldn't reach this point
          p "!!!!!!!!!!!!!!!!!"
          p "Error 1"
        end

        next
      end

      # For testing
      # The code shouldn't reach this point
      p "!!!!!!!!!!!!!!!!!"
      p "Error 2"
    end

    # Testing
    puts "\n---\nTest PGN:\n\n#{str}\n---\nToken Array:\n\n#{tokens}"

    tokens
  end

  def import_pgn(str)
    reset_game

    tokens = tokenize_pgn(str)

    # Parse tag pairs. We're not doing anything with these currently,
    # but at least we have them.
    tags = []
    while tokens.shift == "["
      tags << { symbol: tokens.shift, string: tokens.shift }
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
        # Ignore commentary
        until tokens.shift == "}"
          next
        end
      elsif token == ";"
        # If line commentary, ignore the next token (the commentary string)
        tokens.shift
      elsif token[0] == "$"
        # TODO: Implement NAG, we're skipping these for now
        next
      elsif token == "."
        next
      elsif ALPHA.include?(token[0]) || token[0..1] == "0-"
        # We've encountered a move

        # Fix improper castling notation (it should be O not 0)
        if token == "0-0"
          token = "O-O"
        elsif token == "0-0-0"
          token = "O-O-O"
        end

        if @notation[-1]&.size == 1
          # Black's move
          @notation[-1] << token
          @move_count += 1
        else
          # White's move
          @notation << [token]
        end

        move = parse_move_notation(token)
        p move

        @color_to_move = OTHER_COLOR[@color_to_move]
        @halfmove_total += 1
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
  end

  def parse_move_notation(str)
    color = @color_to_move

    # Castling is a special case, handle it right away
    if ["0-0", "O-O"].include?(str.upcase)
      return { color: color, castle: :kingside }
    elsif ["0-0-0", "O-O-O"].include?(str.upcase)
      return { color: color, castle: :queenside }
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
      color: color,
      type: type,
      square: square,
      capture: capture,
      disambiguation_x: disambiguation_x,
      disambiguation_y: disambiguation_y,
      promotion: promotion,
      check: check,
      checkmate: checkmate,
    }
  end
end
