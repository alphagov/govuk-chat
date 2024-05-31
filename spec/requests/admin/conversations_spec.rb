RSpec.describe "Admin::ConversationsController" do
  let(:conversation) { create(:conversation) }

  describe "GET :show" do
    it "renders the page successfully with questions from newest to oldest" do
      create(:question,  message: "Hello world", conversation:, created_at: 1.day.ago)
      create(:question,  message: "World hello", conversation:, created_at: 1.minute.ago)

      get admin_show_conversation_path(conversation)

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector(".gem-c-title__text", text: "Conversation")
      expect(response.body).to have_selector(".govuk-table") do |match|
        expect(match.text).to match(/World hello.*Hello world/m)
      end
    end

    it "renders 'No questions found' when there are no questions" do
      get admin_show_conversation_path(conversation)

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_content("No questions found")
    end

    it "renders the sortable table headers correctly" do
      create(:question, conversation:)

      get admin_show_conversation_path(conversation)

      expect(response.body)
        .to have_link("Question", href: admin_show_conversation_path(conversation, sort: "message"))
        .and have_link("Created at", href: admin_show_conversation_path(conversation, sort: "created_at"))
        .and have_selector(".govuk-table__header--active .app-table__sort-link--descending", text: "Created at")
        .and have_no_selector(".govuk-table__header--active", text: "Question")
    end

    context "when filter parameters are provided" do
      it "returns success when filters paramaters are valid" do
        get admin_show_conversation_path(conversation, status: "abort_forbidden_words")
        expect(response).to have_http_status(:ok)
      end

      it "returns unprocessable_entity and renders the page with errors when invalid parameters are received" do
        start_date_params = { day: 1, month: 1, year: "invalid" }
        end_date_params = { day: 1, month: 1, year: "invalid" }

        get admin_show_conversation_path(conversation, start_date_params:, end_date_params:)

        expect_unprocessible_entity_with_errors
      end

      it "returns unprocessable_entity and renders the page with errors when partial date parameters are received" do
        start_date_params = { day: 1, month: 1 }
        end_date_params = { day: 1, month: 1 }

        get admin_show_conversation_path(conversation, start_date_params:, end_date_params:)

        expect_unprocessible_entity_with_errors
      end
    end

    context "when the sort param is not the default value" do
      before do
        create(:question, conversation:)
      end

      it "orders the documents correctly when the sort param is 'created_at'" do
        create(:question, message: "Hello world", conversation:, created_at: 1.day.ago)
        create(:question, message: "World hello", conversation:, created_at: 1.minute.ago)

        get admin_show_conversation_path(conversation, sort: "created_at")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/Hello world.*World hello/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is 'created_at'" do
        get admin_show_conversation_path(conversation, sort: "created_at")

        expect(response.body)
        .to have_link("Question", href: admin_show_conversation_path(conversation, sort: "message"))
        .and have_link("Created at", href: admin_show_conversation_path(conversation, sort: "-created_at"))
        .and have_selector(".govuk-table__header--active .app-table__sort-link--ascending", text: "Created at")
        .and have_no_selector(".govuk-table__header--active", text: "Question")
      end

      it "orders the documents correctly when the sort param is 'message'" do
        create(:question, message: "Hello world", conversation:)
        create(:question, message: "World hello", conversation:)

        get admin_show_conversation_path(conversation, sort: "message")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/Hello world.*World hello/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is 'message'" do
        get admin_show_conversation_path(conversation, sort: "message")

        expect(response.body)
        .to have_link("Question", href: admin_show_conversation_path(conversation, sort: "-message"))
        .and have_link("Created at", href: admin_show_conversation_path(conversation, sort: "-created_at"))
        .and have_selector(".govuk-table__header--active .app-table__sort-link--ascending", text: "Question")
        .and have_no_selector(".govuk-table__header--active", text: "Created at")
      end

      it "orders the documents correctly when the sort param is '-message'" do
        create(:question, message: "Hello world", conversation:)
        create(:question, message: "World hello", conversation:)

        get admin_show_conversation_path(conversation, sort: "-message")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/World hello.*Hello world/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is '-message'" do
        get admin_show_conversation_path(conversation, sort: "-message")

        expect(response.body)
        .to have_link("Question", href: admin_show_conversation_path(conversation, sort: "message"))
        .and have_link("Created at", href: admin_show_conversation_path(conversation, sort: "-created_at"))
        .and have_selector(".govuk-table__header--active .app-table__sort-link--descending", text: "Question")
        .and have_no_selector(".govuk-table__header--active", text: "Created at")
      end
    end

    context "when there are more than 25 questions" do
      let(:conversation) { create(:conversation) }

      before do
        create_list(:question, 26, conversation:)
      end

      it "paginates correctly on page 1" do
        get admin_show_conversation_path(conversation)

        expect(response.body)
          .to have_link("Next page", href: admin_show_conversation_path(conversation, page: 2))
          .and have_selector(".govuk-pagination__link-label", text: "2 of 2")
        expect(response.body).not_to have_content("Previous page")
      end

      it "paginates correctly on page 2" do
        get admin_show_conversation_path(conversation, page: "2")

        expect(response.body)
          .to have_link("Previous page", href: admin_show_conversation_path(conversation))
          .and have_selector(".govuk-pagination__link-label", text: "1 of 2")
        expect(response.body).not_to have_content("Next page")
      end

      it "retains the query string parameters when paginating" do
        create_list(:question, 25, conversation:)
        today = Date.current
        query_string_parms = {
          status: "pending",
          start_date_params: { day: today.day, month: today.month, year: today.year - 1 },
          end_date_params: { day: today.day, month: today.month, year: today.year + 1 },
          search: "message",
          sort: "message",
        }

        get admin_show_conversation_path(
          conversation,
          **query_string_parms.merge(page: 2),
        )

        expect(response.body).to have_link("Previous page", href: admin_show_conversation_path(conversation, **query_string_parms))
        expect(response.body).to have_link("Next page", href: admin_show_conversation_path(conversation, **query_string_parms.merge(page: 3)))
      end
    end
  end

  def expect_unprocessible_entity_with_errors
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to have_link("Enter a valid start date", href: "#start_date_params")
    expect(response.body).to have_link("Enter a valid end date", href: "#end_date_params")
  end
end
