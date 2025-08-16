# Constructor and main #tick method for the game runner class which is set
# to `args.state.game` in `main.rb`.
class ChessGame
  def initialize(args)
    @args = args
    @state = args.state

    @screen_width = args.grid.w
    @screen_height = args.grid.h

    @inputs = args.inputs
    @mouse = args.inputs.mouse
    @kb = args.inputs.keyboard

    # Outputs
    @debug = args.outputs.debug
    @sounds = args.outputs.sounds
    @primitives = args.outputs.primitives
    @static_primitives = args.outputs.static_primitives
    @sprites = args.outputs.sprites

    @scene_stack = []
    @scene = :game
    game_init
  end

  def tick
    # Save this so that even if the scene changes during the tick, it is
    # still rendered before switching scenes.
    scene = @scene
    send "#{scene}_tick"
    send "render_#{scene}"

    # Reset game, for development
    if @inputs.keyboard.key_down.backspace
      @args.gtk.reset
    end
  end

  def play_sound(name)
    @args.audio[name] = { input: "sounds/#{name}.mp3" }
  end
end
