class ChessGame
  def init_position_editor
    @editor_multiline = Input::Multiline.new(
      x: 20,
      y: 100,
      w: 170,
      h: 580,
      value: @position_editing[:annotation] || "",
      prompt: "Add annotation...",
      size_enum: :small,
      background_color: [80] * 3,
      blurred_background_color: [80] * 3,
      cursor_color: [255] * 3,
      text_color: [230] * 3,
      selection_color: [30] * 3,
      on_clicked: lambda do |_, input|
        input.focus
      end,
    )
    @editor_multiline.focus

    @editing_buttons = [
      Button.new(
        20, 20, 80, 40,
        "Back", -> { @position_editing = nil },
      ),
      Button.new(
        110, 20, 80, 40,
        "Save", method(:save_position),
      ),
    ]
  end

  def save_position
    annotation = @editor_multiline.value.to_s.strip.gsub("\n", " ")
    @position_editing[:annotation] = annotation.empty? ? nil : annotation
    @position_editing = nil
  end
end
