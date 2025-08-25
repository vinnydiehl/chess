# Portable Game Notation
# Specification: https://www.saremba.de/chessgml/standards/pgn/pgn-complete.htm

# Test PGN
PGN = <<EOS
[Event "F/S Return Match"]
[Site "Belgrade, Serbia JUG"]
[Date "1992.11.04"]
[Round "29"]
[White "Fischer, Robert J.":"P2"]
[Black "Spassky, Boris V."]
[Result "1/2-1/2"]

1.e4 e5 2.Nf3 Nc6 3.Bb5 {This opening is called the Ruy Lopez.} 3...a6
4.Ba4 Nf6 5.O-O Be7 6.Re1 b5 7.Bb3 d6 8.c3 O-O 9.h3 Nb8 10.d4 Nbd7
11.c4 c6 12.cxb5 axb5 13.Nc3 Bb7 14.Bg5 b4 ; Line comment test
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
          if c == "\\"
            # Set escape mode if we need to
            if !escaping
              escaping = true
              next
            end

            # Otherwise we're just escaping a \
            current << c
            escaping = false
          elsif c == '"'
            # End the token at the terminating "
            build = nil
            tokens << current
            current = ""
            next
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
      if current.empty? && ".*:[]()<>".include?(c)
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
    puts "\n#{str}\n---\n"
    p tokens

    tokens
  end
end
