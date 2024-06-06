module AdminQuestionFilterRequestExamples
  shared_examples "a filterable table of questions in the admin interface" do |path, action|
    describe "GET #{action}" do
      it "renders the page successfully with questions from newest to oldest" do
        create(:question, message: "Hello world", created_at: 1.day.ago, conversation: find_or_create_conversation)
        create(:question, message: "World hello", created_at: 1.minute.ago, conversation: find_or_create_conversation)

        get public_send(path, conversation)

        expect(response).to have_http_status(:ok)
        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match.text).to match(/World hello.*Hello world/m)
        end
      end

      it "renders 'No questions found' when there are no questions" do
        get public_send(path, conversation)

        expect(response).to have_http_status(:ok)
        expect(response.body).to have_content("No questions found")
      end

      it "renders the sortable table headers correctly" do
        create(:question, conversation: find_or_create_conversation)

        get public_send(path, conversation)

        expect(response.body)
          .to have_link("Question", href: public_send(path, conversation, sort: "message"))
          .and have_link("Created at", href: public_send(path, conversation, sort: "created_at"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--descending", text: "Created at")
          .and have_no_selector(".govuk-table__header--active", text: "Question")
      end

      context "when there are more than 25 questions" do
        before do
          create_list(:question, 26, conversation: find_or_create_conversation)
        end

        it "paginates correctly on page 1" do
          get public_send(path, conversation)

          expect(response.body)
            .to have_link("Next page", href: public_send(path, conversation, page: 2))
            .and have_selector(".govuk-pagination__link-label", text: "2 of 2")
          expect(response.body).not_to have_content("Previous page")
        end

        it "paginates correctly on page 2" do
          get public_send(path, conversation, page: "2")

          expect(response.body)
            .to have_link("Previous page", href: public_send(path, conversation))
            .and have_selector(".govuk-pagination__link-label", text: "1 of 2")
          expect(response.body).not_to have_content("Next page")
        end
      end

      context "when filter parameters are provided" do
        it "returns success when filters paramaters are valid" do
          get public_send(path, conversation, status: "abort_forbidden_words")
          expect(response).to have_http_status(:ok)
        end

        it "returns unprocessable_entity and renders the page with errors when invalid parameters are received" do
          start_date_params = { day: 1, month: 1, year: "invalid" }
          end_date_params = { day: 1, month: 1, year: "invalid" }

          get public_send(path, conversation, start_date_params:, end_date_params:)

          expect_unprocessible_entity_with_errors
        end

        it "returns unprocessable_entity and renders the page with errors when partial date parameters are received" do
          start_date_params = { day: 1, month: 1 }
          end_date_params = { day: 1, month: 1 }

          get public_send(path, conversation, start_date_params:, end_date_params:)

          expect_unprocessible_entity_with_errors
        end
      end

      context "when the sort param is not the default value" do
        before do
          create(:question, conversation: find_or_create_conversation)
        end

        it "orders the documents correctly when the sort param is 'created_at'" do
          create(:question, message: "Hello world", created_at: 1.day.ago, conversation: find_or_create_conversation)
          create(:question, message: "World hello", created_at: 1.minute.ago, conversation: find_or_create_conversation)

          get public_send(path, conversation, sort: "created_at")

          expect(response.body).to have_selector(".govuk-table") do |match|
            expect(match).to have_content(/Hello world.*World hello/m)
          end
        end

        it "renders the sortable table headers correctly when the sort param is 'created_at'" do
          get public_send(path, conversation, sort: "created_at")

          expect(response.body)
          .to have_link("Question", href: public_send(path, conversation, sort: "message"))
          .and have_link("Created at", href: public_send(path, conversation, sort: "-created_at"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--ascending", text: "Created at")
          .and have_no_selector(".govuk-table__header--active", text: "Question")
        end

        it "orders the documents correctly when the sort param is 'message'" do
          create(:question, message: "Hello world", conversation: find_or_create_conversation)
          create(:question, message: "World hello", conversation: find_or_create_conversation)

          get public_send(path, conversation, sort: "message")

          expect(response.body).to have_selector(".govuk-table") do |match|
            expect(match).to have_content(/Hello world.*World hello/m)
          end
        end

        it "renders the sortable table headers correctly when the sort param is 'message'" do
          get public_send(path, conversation, sort: "message")

          expect(response.body)
          .to have_link("Question", href: public_send(path, conversation, sort: "-message"))
          .and have_link("Created at", href: public_send(path, conversation, sort: "-created_at"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--ascending", text: "Question")
          .and have_no_selector(".govuk-table__header--active", text: "Created at")
        end

        it "orders the documents correctly when the sort param is '-message'" do
          create(:question, message: "Hello world", conversation: find_or_create_conversation)
          create(:question, message: "World hello", conversation: find_or_create_conversation)

          get public_send(path, conversation, sort: "-message")

          expect(response.body).to have_selector(".govuk-table") do |match|
            expect(match.text).to match(/World hello.*Hello world/m)
          end
        end

        it "renders the sortable table headers correctly when the sort param is '-message'" do
          get public_send(path, conversation, sort: "-message")

          expect(response.body)
          .to have_link("Question", href: public_send(path, conversation, sort: "message"))
          .and have_link("Created at", href: public_send(path, conversation, sort: "-created_at"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--descending", text: "Question")
          .and have_no_selector(".govuk-table__header--active", text: "Created at")
        end
      end
    end

    def expect_unprocessible_entity_with_errors
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to have_link("Enter a valid start date", href: "#start_date_params")
      expect(response.body).to have_link("Enter a valid end date", href: "#end_date_params")
    end

    def find_or_create_conversation
      conversation || create(:conversation)
    end
  end
end
