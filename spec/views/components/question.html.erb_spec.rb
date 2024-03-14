RSpec.describe "components/_question.html.erb" do
  it "renders the answer component correctly" do
    render("components/question", {
      id: "question-1",
      message: "message 1",
    })

    assert_select "div.app-c-question#question-1" do
      assert_select ".app-c-question__identifier .app-c-question__identifier-icon"
      assert_select ".app-c-question__identifier .app-c-question__identifier-heading", text: "You"
      assert_select ".app-c-question__message", text: "message 1"
    end
  end

  it "applies data attributes when provided" do
    render("components/question", {
      id: "question-1",
      message: "This has data attributes.",
      data_attributes: {
        track_category: "track-category",
        track_action: "track-action",
        track_label: "track-label",
      },
    })

    assert_select '.app-c-question[data-track-category="track-category"]'
    assert_select '.app-c-question[data-track-action="track-action"]'
    assert_select '.app-c-question[data-track-label="track-label"]'
  end
end
