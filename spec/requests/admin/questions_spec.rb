RSpec.describe "Admin::QuestionsController" do
  it_behaves_like "a filterable table of questions in the admin interface",
                  :admin_questions_path,
                  ":index" do
    let(:conversation) { nil }
  end

  describe "GET :show" do
    it "renders the page successfully" do
      question = create(:question)
      get admin_show_question_path(question)

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_content(question.message)
    end

    it "renders a link to the search results page" do
      question = create(:question)
      get admin_show_question_path(question)

      expect(response.body).to have_content("Show search results")
      href = admin_search_path(params: { search_text: question.message })
      expect(response.body).to have_selector("a.govuk-link[href='#{href}']", text: question.message)
    end

    it "renders a link to the search results with rephrased question" do
      question = create(:question, :with_answer)
      question.answer.update!(rephrased_question: "how do I pay self assessment")
      get admin_show_question_path(question)

      expect(response.body).to have_content("Show search results")
      href = admin_search_path(params: { search_text: "how do I pay self assessment" })
      expect(response.body).to have_selector("a.govuk-link[href='#{href}']", text: "how do I pay self assessment")
    end

    it "renders the details for an answer when present" do
      question = create(:question, :with_answer)
      answer = question.answer

      get admin_show_question_path(question)

      expect(response.body).to have_content(answer.message)
    end

    it "renders the sources for an answer when present" do
      question = create(:question)
      answer = create(:answer, question:, sources: [create(:answer_source), create(:answer_source, used: false)])
      used_source = answer.sources.first
      unused_source = answer.sources.last

      get admin_show_question_path(question)

      expect(response.body)
        .to have_content("Used sources")
        .and have_link(used_source.title, href: used_source.url)
        .and have_content("Unused sources")
        .and have_link(unused_source.title, href: unused_source.url)
    end

    it "renders the feedback for an answer when present" do
      question = create(:question)
      answer = create(:answer, question:)
      create(:answer_feedback, answer:, useful: true)

      get admin_show_question_path(question)

      expect(response.body)
        .to have_content("Feedback created at")
        .and have_content("Useful")
    end

    it "renders the metrics" do
      metrics = {
        "answer_composition" => { duration: 1.55556 },
        "question_rephrasing" => { duration: 0.55, llm_prompt_tokens: 400, llm_completion_tokens: 101 },
      }

      question = create(:question)
      create(:answer, question:, metrics:)

      get admin_show_question_path(question)

      expect(response.body).to have_content("Metrics")

      expect(response.body.squish)
        .to have_content("answer_composition")
        .and have_content(/duration.*1\.55556/)

      expect(response.body.squish)
        .to have_content("question_rephrasing")
        .and have_content(/duration.*0\.55/)
        .and have_content(/llm_prompt_tokens.*400/)
        .and have_content(/llm_completion_tokens.*101/)
    end
  end
end
