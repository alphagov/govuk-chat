RSpec.describe "components/_conversation_input.html.erb" do
  it "renders the conversation input component correctly" do
    render("components/conversation_input", {
      label: "Label",
      name: "Name",
      value: "Value",
      hint: "Hint",
      maxlength: 300,
      character_threshold: 50,
      spellcheck: true,
    })

    assert_select ".app-c-conversation-input" do
      assert_select ".app-c-conversation-input__wrapper"
      assert_select ".app-c-conversation-input__wrapper .app-c-conversation-input__label.govuk-visually-hidden", text: "Label"
      assert_select ".app-c-conversation-input__wrapper .app-c-conversation-input__input"
      assert_select ".app-c-conversation-input__wrapper .app-c-conversation-input__submit", text: "Send"
      assert_select ".gem-c-hint.govuk-hint", text: "Hint"
      assert_select "[data-maxlength=?]", 300
      assert_select "[data-character-threshold=?]", 50
    end

    assert_select ".app-c-conversation-input__wrapper .app-c-conversation-input__input" do
      assert_select "[name=?]", "Name"
      assert_select "[value=?]", "Value"
      assert_select "[aria-describedby]"
    end
  end

  it "applies data attributes when provided" do
    render("components/conversation_input", {
      data_attributes: {
        track_category: "track-category",
        track_action: "track-action",
        track_label: "track-label",
      },
      label: "Label",
      name: "Name",
      value: "Value",
      hint: "Hint",
      maxlength: 300,
      character_threshold: 50,
      spellcheck: true,
    })

    assert_select '.app-c-conversation-input[data-track-category="track-category"]'
    assert_select '.app-c-conversation-input[data-track-action="track-action"]'
    assert_select '.app-c-conversation-input[data-track-label="track-label"]'
  end

  it "renders error messages when there is a problem" do
    render("components/conversation_input", {
      label: "Label",
      name: "Name",
      value: "Value",
      hint: "Hint",
      error_items: [
        {
          text: "Error 1",
        },
      ],
      maxlength: 300,
      character_threshold: 50,
      spellcheck: true,
    })

    assert_select ".gem-c-error-message.govuk-error-message"
    assert_select ".gem-c-error-message.govuk-error-message", text: "Error: Error 1"
  end

  it "matches the input's aria-describedby attribute with a hint id when a hint is provided" do
    render("components/conversation_input", {
      label: "Label",
      name: "Name",
      value: "Value",
      hint: "Hint",
      hint_id: "hint-id",
      maxlength: 300,
      character_threshold: 50,
      spellcheck: true,
    })

    assert_select ".gem-c-hint.govuk-hint[id=hint-id]"
    assert_select ".app-c-conversation-input__wrapper .app-c-conversation-input__input" do
      assert_select "[aria-describedby=?]", "hint-id"
    end
  end

  it "matches the input's aria-describedby attribute with an error id when there are errors" do
    render("components/conversation_input", {
      label: "Label",
      name: "Name",
      value: "Value",
      hint: "Hint",
      hint_id: "hint-id",
      error_items: [
        {
          text: "Error 1",
        },
        {
          text: "Error 2",
        },
      ],
      error_id: "error-id",
      maxlength: 300,
      character_threshold: 50,
      spellcheck: true,
    })

    assert_select ".gem-c-error-message.govuk-error-message[id=error-id]"
    assert_select ".gem-c-error-message.govuk-error-message[id=error-id]", text: "Error: Error 1Error 2"
    assert_select ".app-c-conversation-input__wrapper .app-c-conversation-input__input" do
      assert_select "[aria-describedby=?]", "hint-id error-id"
    end
  end
end
