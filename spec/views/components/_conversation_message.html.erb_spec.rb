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

    context "and is_loading is true" do
      it "renders the loading text" do
        render("components/conversation_message", {
          id: "loading-question",
          is_question: true,
          is_loading: true,
        })

        expect(rendered).to have_selector("li.app-c-conversation-message#loading-question") do |rendered_question|
          expect(rendered_question)
            .to have_selector(".app-c-conversation-message__loading-text", text: "Loading your question")
            .and have_selector(".app-c-conversation-message__loading-ellipsis", text: "...")
        end
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

    it "renders sources as titles in the sources component when provided" do
      render("components/conversation_message", {
        id: "answer-3",
        message: "message 4",
        sources: [
          {
            title: "Example 1",
            href: "http://example.com",
          },
          {
            title: "Example 2",
            href: "http://example.gov.uk",
          },
        ],
      })

      expect(rendered)
        .to have_link("Example 1", href: "http://example.com", visible: :all)
        .and have_link("Example 2", href: "http://example.gov.uk", visible: :all)
    end

    it "sanitises the message" do
      render("components/conversation_message", {
        id: "answer-2",
        message: "<script>alert('hackerman')</script>",
      })

      expect(rendered)
        .to have_selector(".app-c-conversation-message__answer .govuk-govspeak", text: "alert('hackerman')")
    end

    context "and is_loading is true" do
      it "renders the loading text" do
        render("components/conversation_message", {
          id: "loading-answer",
          is_loading: true,
        })

        expect(rendered).to have_selector("li.app-c-conversation-message#loading-answer") do |rendered_question|
          expect(rendered_question)
            .to have_selector(".app-c-conversation-message__loading-text", text: "Generating your answer")
            .and have_selector(".app-c-conversation-message__loading-ellipsis", text: "...")
        end
      end
    end
  end

  context "when a feedback url is passed" do
    it "renders the answer feedback component" do
      render("components/conversation_message", {
        id: "answer-4",
        message: "message 4",
        question_message: "How do I apply for teacher training?",
        feedback_url: "http://example.com",
      })

      expect(rendered).to have_selector(".app-c-answer-feedback__form[action='http://example.com']")
    end
  end

  it "does not render messages using govspeak when omit_govspeak is true" do
    render("components/conversation_message", {
      id: "answer-5",
      message: "Test message",
      omit_govspeak: true,
    })

    expect(rendered)
      .not_to have_selector(".app-c-conversation-message .app-c-conversation-message__answer .gem-c-govspeak.govuk-govspeak")
  end

  it "renders messages using govspeak when omit_govspeak is omitted" do
    render("components/conversation_message", {
      id: "answer-6",
      message: "Test message",
    })

    expect(rendered)
      .to have_selector(".app-c-conversation-message .app-c-conversation-message__answer .gem-c-govspeak.govuk-govspeak")
  end
end
