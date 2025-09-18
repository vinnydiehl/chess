FEN_MENU_BUTTON_WIDTH = 100
FEN_MENU_BUTTON_HEIGHT = 40
FEN_MENU_BUTTON_PADDING = 20

class ChessGame
  def fen_menu_init
    @multiline = Input::Multiline.new(
      x: 20,
      y: 100,
      w: 1240,
      h: 580,
      value: get_fen,
      prompt: "Insert FEN",
      size_enum: :xlarge,
      background_color: [80] * 3,
      blurred_background_color: [80] * 3,
      cursor_color: [255] * 3,
      text_color: [230] * 3,
      selection_color: [30] * 3,
      on_clicked: lambda do |_, input|
        input.focus
      end,
    )
    @multiline.focus

    @fen_buttons = [
      Button.new(
        @cx - FEN_MENU_BUTTON_WIDTH - (FEN_MENU_BUTTON_PADDING / 2),
        30,
        FEN_MENU_BUTTON_WIDTH,
        FEN_MENU_BUTTON_HEIGHT,
        "Back", -> { set_scene_back },
      ),
      Button.new(
        @cx + (FEN_MENU_BUTTON_PADDING / 2),
        30,
        FEN_MENU_BUTTON_WIDTH,
        FEN_MENU_BUTTON_HEIGHT,
        "Load", -> {
          load_fen(@multiline.value.to_s)
          set_scene_back
        },
      ),
    ]
  end

  def fen_menu_tick
    @multiline.tick
    @fen_buttons.each(&:tick)

    if @kb.key_down?(:escape)
      set_scene_back
    end
  end
end
