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

    assert_select '.app-c-conversation-message[data-track-category="track-category"]'
    assert_select '.app-c-conversation-message[data-track-action="track-action"]'
    assert_select '.app-c-conversation-message[data-track-label="track-label"]'
  end

  context "when is_question is true" do
    it "renders the message component correctly" do
      render("components/conversation_message", {
        id: "question-1",
        message: "message 2",
        is_question: true,
      })

      assert_select "div.app-c-conversation-message#question-1" do
        assert_select ".app-c-conversation-message__identifier .app-c-conversation-message__identifier-icon.app-c-conversation-message__identifier-icon--user-icon"
        assert_select ".app-c-conversation-message__identifier .app-c-conversation-message__identifier-heading", text: "You"
        assert_select ".app-c-conversation-message__body.app-c-conversation-message__body--user-message", text: "message 2"
      end
    end
  end

  context "when is_question is false/not passed" do
    it "renders the message component correctly" do
      render("components/conversation_message", {
        id: "answer-2",
        message: "message 3",
      })

      assert_select "div.app-c-conversation-message#answer-2" do
        assert_select ".app-c-conversation-message__identifier .app-c-conversation-message__identifier-icon.app-c-conversation-message__identifier-icon--govuk-chat-icon"
        assert_select ".app-c-conversation-message__identifier .app-c-conversation-message__identifier-heading", text: "GOV.UK Chat (experimental)"
        assert_select ".app-c-conversation-message__answer .govuk-govspeak", text: "message 3"
        assert_select ".govuk-details", count: 0
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

      assert_select ".govuk-details a[href='http://example.com']", text: "http://example.com"
      assert_select ".govuk-details a[href='http://example.gov.uk']", text: "http://example.gov.uk"
    end

    it "sanitises the message" do
      render("components/conversation_message", {
        id: "answer-2",
        message: "<script>alert('hackerman')</script>",
      })

      assert_select ".app-c-conversation-message__answer .govuk-govspeak", text: "alert('hackerman')"
    end
  end
end
