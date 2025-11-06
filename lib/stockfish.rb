class Stockfish
  attr_reader :variations

  def initialize
    # These debug lines are commented out for now, eventually I want to log
    # this output in a file.
    # puts "[INFO] Starting Stockfish..."
    @engine = IO.popen("stockfish", "r+")
    @engine.sync = true
    unless @engine.gets
      raise "[ERROR] Stockfish is not installed."
      @engine.close
      return
    end

    @commands = []
    @awaiting_ready = false
    @awaiting_bestmove = false

    write("uci")

    @variations = {}
  end

  # This must run every game tick. It asynchronously communicates with Stockfish,
  # reading any available output and writing any queued commands when able.
  def tick
    # If there are any commands queued we need to check ready so they can execute
    if @commands.any? && !@awaiting_ready
      check_ready
    end

    # Process all available output lines
    while (line = next_line)
      # puts "[SF] #{line}"

      if line == "readyok"
        @awaiting_ready = false
        if @commands.any? && !@awaiting_bestmove
          command = @commands.shift
          # puts "[INFO] Engine ready, sending command: #{command}"
          write(command)

          if command == "stop"
            @awaiting_bestmove = true
          end
        end

        next
      end

      if line.include?("bestmove")
        @awaiting_bestmove = false
      end

      # Parse MultiPVs
      if line.include?("multipv") && line.include?("pv")
        words = line.split

        # Find the indices of the keywords
        multipv_index = words.index("multipv")
        pv_index = words.index("pv")

        # Extract values
        multipv = words[multipv_index + 1].to_i
        pv_moves = words[(pv_index + 1)..-1].join(" ")

        @variations[multipv] = pv_moves
      end
    end
  end

  # Queues a command to send as soon as the engine is ready.
  def send_command(command)
    @commands << command
  end

  # Sets an option within the engine.
  def set_option(name, value)
    send_command("setoption name #{name} value #{value}")
  end

  # Sets the game state to a given FEN.
  def set_fen(fen)
    send_command("position fen #{fen}")
  end

  # Begins calculating the current position.
  def go
    send_command("go infinite")
  end

  # Stops calculation.
  def stop
    send_command("stop")
  end

  private

  # Returns the next line if there's one available to read, otherwise returns nil.
  def next_line
    # Check if there's anything ready to read so that IO#gets doesn't block
    return nil unless IO.select([@engine], nil, nil, 0)
    @engine.gets.chomp
  end

  # Sends an isready command. @status will be set to :ready once a readyok
  # command is received.
  def check_ready
    return if @awaiting_ready
    # puts "[INFO] Checking ready"
    @awaiting_ready = true
    write("isready")
  end

  # Writes to the engine's input stream.
  def write(str)
    @engine.puts(str)
  end
end
