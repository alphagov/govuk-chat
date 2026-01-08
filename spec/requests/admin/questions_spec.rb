RSpec.describe "Admin::QuestionsController" do
  describe "GET index" do
    it "renders the page successfully with questions from newest to oldest" do
      create(:question, message: "Hello world", created_at: 1.day.ago)
      create(:question, message: "World hello", created_at: 1.minute.ago)

      get admin_questions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector(".govuk-table") do |match|
        expect(match.text).to match(/World hello.*Hello world/m)
      end
    end

    it "renders 'No questions found' when there are no questions" do
      get admin_questions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_content("No questions found")
    end

    it "renders the sortable table headers correctly" do
      create(:question)

      get admin_questions_path

      expect(response.body)
        .to have_link("Question", href: admin_questions_path(sort: "message"))
        .and have_link("Created at", href: admin_questions_path(sort: "created_at"))
        .and have_selector(".govuk-table__header--active .app-table__sort-link--descending", text: "Created at")
        .and have_no_selector(".govuk-table__header--active", text: "Question")
    end

    context "when there are more than 25 questions" do
      before do
        create_list(:question, 26)
      end

      it "paginates correctly on page 1" do
        get admin_questions_path

        expect(response.body)
          .to have_link("Next page", href: admin_questions_path(page: 2))
          .and have_selector(".govuk-pagination__link-label", text: "2 of 2")
        expect(response.body).not_to have_content("Previous page")
      end

      it "paginates correctly on page 2" do
        get admin_questions_path(page: "2")

        expect(response.body)
          .to have_link("Previous page", href: admin_questions_path)
          .and have_selector(".govuk-pagination__link-label", text: "1 of 2")
        expect(response.body).not_to have_content("Next page")
      end
    end

    context "when filter parameters are provided" do
      it "returns success when filters paramaters are valid" do
        get admin_questions_path(status: "error_timeout")
        expect(response).to have_http_status(:ok)
      end

      it "returns unprocessable_content and renders the page with errors when invalid parameters are received" do
        start_date_params = { day: 1, month: 1, year: "invalid" }
        end_date_params = { day: 1, month: 1, year: "invalid" }

        get admin_questions_path(start_date_params:, end_date_params:)

        expect_unprocessable_content_with_date_errors
      end

      it "returns unprocessable_content and renders the page with errors when partial date parameters are received" do
        start_date_params = { day: 1, month: 1 }
        end_date_params = { day: 1, month: 1 }

        get admin_questions_path(start_date_params:, end_date_params:)

        expect_unprocessable_content_with_date_errors
      end

      it "renders a conversation_id when filtering by a conversation_id" do
        conversation = create(:conversation)
        get admin_questions_path(conversation_id: conversation.id)

        expect(response.body.squish).to have_content("Filtering by conversation ID:   #{conversation.id}")
      end

      it "renders the signon user's details when filtering by signon_user_id" do
        signon_user = create(:signon_user)
        create(:conversation, signon_user:)
        get admin_questions_path(signon_user_id: signon_user.id)

        expect(response.body.squish)
          .to have_content("Filtering by Signon user: #{signon_user.name}")
      end

      it "renders the end user details when filtering by end_user_id" do
        create(:conversation, end_user_id: "alice")
        get admin_questions_path(end_user_id: "alice")

        expect(response.body.squish)
          .to have_content('Filtering by end user: "alice"')
      end
    end

    context "when the sort param is not the default value" do
      before do
        create(:question)
      end

      it "orders the documents correctly when the sort param is 'created_at'" do
        create(:question, message: "Hello world", created_at: 1.day.ago)
        create(:question, message: "World hello", created_at: 1.minute.ago)

        get admin_questions_path(sort: "created_at")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/Hello world.*World hello/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is 'created_at'" do
        get admin_questions_path(sort: "created_at")

        expect(response.body)
        .to have_link("Question", href: admin_questions_path(sort: "message"))
        .and have_link("Created at", href: admin_questions_path(sort: "-created_at"))
        .and have_selector(".govuk-table__header--active .app-table__sort-link--ascending", text: "Created at")
        .and have_no_selector(".govuk-table__header--active", text: "Question")
      end

      it "orders the documents correctly when the sort param is 'message'" do
        create(:question, message: "Hello world")
        create(:question, message: "World hello")

        get admin_questions_path(sort: "message")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/Hello world.*World hello/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is 'message'" do
        get admin_questions_path(sort: "message")

        expect(response.body)
        .to have_link("Question", href: admin_questions_path(sort: "-message"))
        .and have_link("Created at", href: admin_questions_path(sort: "-created_at"))
        .and have_selector(".govuk-table__header--active .app-table__sort-link--ascending", text: "Question")
        .and have_no_selector(".govuk-table__header--active", text: "Created at")
      end

      it "orders the documents correctly when the sort param is '-message'" do
        create(:question, message: "Hello world")
        create(:question, message: "World hello")

        get admin_questions_path(sort: "-message")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match.text).to match(/World hello.*Hello world/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is '-message'" do
        get admin_questions_path(sort: "-message")

        expect(response.body)
        .to have_link("Question", href: admin_questions_path(sort: "message"))
        .and have_link("Created at", href: admin_questions_path(sort: "-created_at"))
        .and have_selector(".govuk-table__header--active .app-table__sort-link--descending", text: "Question")
        .and have_no_selector(".govuk-table__header--active", text: "Created at")
      end
    end
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
        .and have_link(used_source.title, href: used_source.govuk_url)
        .and have_content("Unused sources")
        .and have_link(unused_source.title, href: unused_source.govuk_url)
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

    it "renders the answer metrics" do
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

    it "renders the answer LLM responses" do
      llm_responses = {
        "structured_answer" => {
          "tool_calls": [
            { "id": "call_dqGpbb39drQDafLsjDLtnbGD" },
          ],
        },
      }

      question = create(:question)
      create(:answer, question:, llm_responses:)

      get admin_show_question_path(question)

      expect(response.body).to have_content("LLM responses")

      expect(response.body.squish)
        .to have_content("structured_answer")
        .and have_content("tool_calls")
        .and have_content('"id": "call_dqGpbb39drQDafLsjDLtnbGD"')
    end

    it "doesn't render the tabs component when there are no topics or auto-eval aggregate data" do
      question = create(:question, :with_answer)
      get admin_show_question_path(question)

      expect(response.body).not_to have_content("govuk-tabs")
    end

    context "when topics are present" do
      let!(:topics) do
        create(
          :answer_analysis_topics,
          primary_topic: "business",
          secondary_topic: "tax",
          metrics: {
            topic_tagger: {
              duration: 1.5,
              llm_prompt_tokens: 30,
              llm_completion_tokens: 20,
              llm_cached_tokens: 20,
              model: BedrockModels.model_id(:claude_sonnet),
            },
          },
          llm_responses: {
            "topic_tagger" => {
              "tool_calls": [
                { "id": "topic_tool_call" },
              ],
            },
          },
        )
      end
      let(:question) { topics.answer.question }

      it "renders the topics" do
        get admin_show_question_path(question)

        expect(response.body)
          .to have_content("Business")
          .and have_content("Tax")
      end

      it "renders the topic metrics" do
        get admin_show_question_path(question)

        expect(response.body.squish)
          .to have_content("topic_tagger")
          .and have_content(/duration.*1\.5/)
          .and have_content(/llm_prompt_tokens.*30/)
          .and have_content(/llm_completion_tokens.*20/)
          .and have_content(/llm_cached_tokens.*20/)
          .and have_content(/model.*#{BedrockModels.model_id(:claude_sonnet)}/)
      end

      it "renders the topics LLM responses" do
        get admin_show_question_path(question)

        expect(response.body.squish)
          .to have_content("topic_tagger")
          .and have_content("tool_calls")
          .and have_content('"id": "topic_tool_call"')
      end

      it "renders the question details in the details tab" do
        get admin_show_question_path(question)

        expect(response.body)
          .to have_selector("#details-tab", text: question.message)
      end

      it "renders the topics in the analysis tab" do
        get admin_show_question_path(question)

        expect(response.body)
         .to have_selector("#analysis-tab", text: topics.primary_topic.capitalize)
         .and have_selector("#analysis-tab", text: topics.secondary_topic.capitalize)
      end
    end

    context "when answer relevancy aggregate data is present" do
      let(:run) do
        create(
          :answer_relevancy_run,
          score: 0.85,
          reason: "The answer is relevant to the question.",
          llm_responses: {
            "statements" => { "statements" => ["The answer is relevant."] },
            "verdicts" => { "verdicts" => [{ "verdict" => "yes" }] },
          },
          metrics: {
            "statements" => { duration: 1.55556 },
            "verdicts" => { duration: 1.44445 },
          },
        )
      end
      let(:question) { run.answer.question }

      it "renders the answer relevancy aggregate and run details" do
        get admin_show_question_path(question)

        expect(response.body.squish)
          .to have_content("Answer relevancy")
          .and have_content("Run 1 score")
          .and have_content("0.85")
          .and have_content("Run 1 reason")
          .and have_content("The answer is relevant to the question.")
      end

      it "renders the runs llm responses" do
        get admin_show_question_path(question)

        expect(response.body.squish)
          .to have_content('{ "statements": [ "The answer is relevant." ] }')
          .and have_content('{ "verdicts": [ { "verdict": "yes" } ] }')
      end

      it "renders the runs metrics" do
        get admin_show_question_path(question)

        expect(response.body.squish)
          .to have_content("Statements")
          .and have_content(/duration.*1\.55556/)
          .and have_content("Verdicts")
          .and have_content(/duration.*1\.44445/)
      end
    end
  end

  def expect_unprocessable_content_with_date_errors
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to have_link("Enter a valid start date", href: "#start_date_params")
    expect(response.body).to have_link("Enter a valid end date", href: "#end_date_params")
  end
end
