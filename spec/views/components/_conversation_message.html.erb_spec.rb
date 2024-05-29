RSpec.describe "components/_conversation_message.html.erb" do
  it "applies data attributes when provided" do
    render("components/conversation_message", {
      id: "answer-1",
      message: "message 1",
      data_attributes: {
        track_category: "track-category",
        track_action: "track-action",
        track_label: "track-label",
      },
    })

    expect(rendered)
      .to have_selector('.app-c-conversation-message[data-track-category="track-category"]')
      .and have_selector('.app-c-conversation-message[data-track-action="track-action"]')
      .and have_selector('.app-c-conversation-message[data-track-label="track-label"]')
  end

  context "when is_question is true" do
    it "renders the message component correctly" do
      render("components/conversation_message", {
        id: "question-1",
        message: "message 2",
        is_question: true,
      })

      expect(rendered).to have_selector("li.app-c-conversation-message#question-1") do |rendered_question|
        expect(rendered_question)
          .to have_selector(".app-c-conversation-message__identifier .govuk-visually-hidden", text: "You:")
          .and have_selector(".app-c-conversation-message__body.app-c-conversation-message__body--user-message", text: "message 2")
      end
    end
  end

  context "when is_question is false/not passed" do
    it "renders the message component correctly" do
      render("components/conversation_message", {
        id: "answer-2",
        message: "message 3",
      })

      expect(rendered).to have_selector("li.app-c-conversation-message#answer-2") do |rendered_answer|
        expect(rendered_answer)
          .to have_selector(".app-c-conversation-message__identifier .app-c-conversation-message__identifier-icon")
          .and have_selector(".app-c-conversation-message__identifier .govuk-visually-hidden", text: "GOV.UK Chat:")
          .and have_selector(".app-c-conversation-message__answer .govuk-govspeak", text: "message 3")
          .and have_selector(".govuk-details", count: 0)
      end
    end

    it "renders sources as links in a details component when provided" do
      render("components/conversation_message", {
        id: "answer-3",
        message: "message 4",
        sources: [
          "http://example.com",
          "http://example.gov.uk",
        ],
      })

      expect(rendered)
        .to have_selector(".gem-c-list a[href='http://example.com']", text: "http://example.com", visible: :all)
        .and have_selector(".gem-c-list a[href='http://example.gov.uk']", text: "http://example.gov.uk", visible: :all)
    end

    it "sanitises the message" do
      render("components/conversation_message", {
        id: "answer-2",
        message: "<script>alert('hackerman')</script>",
      })

      expect(rendered)
        .to have_selector(".app-c-conversation-message__answer .govuk-govspeak", text: "alert('hackerman')")
    end
  end
end
