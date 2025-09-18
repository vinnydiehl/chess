# Constructor and main #tick method for the game runner class which is set
# to `args.state.game` in `main.rb`.
class ChessGame
  def initialize(args)
    @args = args
    @state = args.state

    @screen_width = args.grid.w
    @screen_height = args.grid.h
    @cx = @screen_width / 2
    @cy = @screen_height / 2

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
    set_scene(:game, reset_stack: true)
  end

  def set_scene(scene, reset_stack: false)
    @scene_stack = [] if reset_stack
    @scene = scene
    @scene_stack << scene

    ["#{scene}_init", "render_#{scene}_init"].each do |method|
      send method if respond_to?(method)
    end
  end

  def set_scene_back
    @scene_stack.pop
    @scene = @scene_stack.last
  end

  def tick
    # Save this so that even if the scene changes during the tick, it is
    # still rendered before switching scenes.
    scene = @scene
    send "#{scene}_tick"
    send "render_#{scene}"

    # Reset game, for development
    if @kb.key_down_or_held?(:shift) && @kb.key_down?(:backspace)
      @args.gtk.reboot
    end
  end

  def play_sound(name)
    @args.audio[name] = { input: "sounds/#{name}.mp3" }
  end
end
