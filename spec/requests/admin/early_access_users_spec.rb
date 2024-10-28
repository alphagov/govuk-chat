RSpec.describe "Admin::EarlyAccessUsersController" do
  describe "GET :index" do
    it "renders the page successfully" do
      get admin_early_access_users_path

      expect(response).to have_http_status(:ok)
    end

    it "renders an empty state" do
      get admin_early_access_users_path

      expect(response.body).to have_content("No users found")
    end

    it "renders the table headers correctly" do
      create(:early_access_user)

      get admin_early_access_users_path

      expect(response.body)
        .to have_link("Email", href: admin_early_access_users_path(sort: "email"))
        .and have_link("Last login", href: admin_early_access_users_path(sort: "last_login_at"))
        .and have_link("Questions", href: admin_early_access_users_path(sort: "-questions_count"))
        .and have_selector(".govuk-table__header", text: "Access revoked?")
    end

    it "renders the table body correctly" do
      user = create(:early_access_user, email: "alice@example.com")

      get admin_early_access_users_path

      expect(response.body)
        .to have_link("alice@example.com", href: admin_early_access_user_path(user))
    end

    it "does not link to a user's questions if they have 0 questions" do
      create(:early_access_user, email: "alice@example.com")

      get admin_early_access_users_path

      expect(response.body).to have_selector(".govuk-table__cell", exact_text: "0")
    end

    it "links to a user's questions without a total if they have no question limit" do
      user = create(:early_access_user, email: "alice@example.com", questions_count: 5, individual_question_limit: 0)

      get admin_early_access_users_path

      expect(response.body).to have_link("5", href: admin_questions_path(user_id: user.id))
      expect(response.body).to have_selector(".govuk-table__cell", exact_text: "5")
    end

    it "links to a user's questions with a total if they have a fixed question limit" do
      user = create(:early_access_user, email: "alice@example.com", questions_count: 5, individual_question_limit: 70)

      get admin_early_access_users_path

      expect(response.body).to have_link("5", href: admin_questions_path(user_id: user.id))
      expect(response.body).to have_selector(".govuk-table__cell", exact_text: "5 / 70")
    end

    it "links to a user's questions with a total if they have a default question limit" do
      user = create(:early_access_user, email: "alice@example.com", questions_count: 5)
      default_question_limit = Rails.configuration.conversations.max_questions_per_user

      get admin_early_access_users_path

      expect(response.body).to have_link("5", href: admin_questions_path(user_id: user.id))
      expect(response.body).to have_selector(".govuk-table__cell", exact_text: "5 / #{default_question_limit}")
    end

    context "when there are multiple pages of users" do
      before do
        create_list(:early_access_user, 26)
      end

      it "paginates correctly on page 1" do
        get admin_early_access_users_path

        expect(response.body)
          .to have_link("Next page", href: admin_early_access_users_path(page: 2))
          .and have_selector(".govuk-pagination__link-label", text: "2 of 2")
        expect(response.body).not_to have_content("Previous page")
      end

      it "paginates correctly on page 2" do
        get admin_early_access_users_path(page: 2)

        expect(response.body)
          .to have_link("Previous page", href: admin_early_access_users_path)
          .and have_selector(".govuk-pagination__link-label", text: "1 of 2")
        expect(response.body).not_to have_content("Next page")
      end
    end

    context "when filter parameters are provided" do
      context "and user source is filtered by 'Instant Signup'" do
        it "displays users with a source of 'Instant Signup and filters out others" do
          create(:early_access_user, email: "a@example.com", source: "instant_signup")
          create(:early_access_user, email: "b@example.com", source: "admin_added")
          get admin_early_access_users_path(source: "instant_signup")

          expect(response).to have_http_status(:ok)
          expect(response.body).to have_selector(".govuk-table") do |match|
            expect(match).to have_content(/a@example\.com/)
            expect(match).not_to have_content(/b@example\.com/)
          end
        end
      end

      context "and users are filtered by 'Revoked'" do
        it "displays user accounts which have been revoked and filters out those which have not" do
          create(:early_access_user, email: "a@example.com", revoked_at: Time.zone.now)
          create(:early_access_user, email: "b@example.com")
          get admin_early_access_users_path(revoked: true)

          expect(response).to have_http_status(:ok)
          expect(response.body).to have_selector(".govuk-table") do |match|
            expect(match).to have_content(/a@example\.com/)
            expect(match).not_to have_content(/b@example\.com/)
          end
        end
      end

      context "and users are filtered by 'At Question Limit'" do
        it "displays user accounts at their question limit and filters out those which are not" do
          create(:early_access_user, email: "a@example.com", questions_count: 100, individual_question_limit: 100)
          create(:early_access_user, email: "c@example.com", questions_count: 23)
          get admin_early_access_users_path(at_question_limit: true)

          expect(response).to have_http_status(:ok)
          expect(response.body).to have_selector(".govuk-table") do |match|
            expect(match).to have_content(/a@example\.com/)
            expect(match).not_to have_content(/b@example\.com/)
          end
        end
      end
    end

    context "when sorting" do
      it "orders the users correctly when the sort param is 'last_login_at'" do
        create(:early_access_user, email: "a@example.com", last_login_at: 1.hour.ago)
        create(:early_access_user, email: "b@example.com", last_login_at: 1.day.ago)
        create(:early_access_user, email: "c@example.com", last_login_at: 1.minute.ago)

        get admin_early_access_users_path(sort: "last_login_at")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/b@example\.com.*a@example\.com.*c@example\.com/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is 'last_login_at'" do
        create(:early_access_user)

        get admin_early_access_users_path(sort: "last_login_at")

        expect(response.body)
          .to have_link("Last login", href: admin_early_access_users_path(sort: "-last_login_at"))
          .and have_link("Questions", href: admin_early_access_users_path(sort: "-questions_count"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--ascending", text: "Last login")
          .and have_link("Email", href: admin_early_access_users_path(sort: "email"))
          .and have_no_selector(".govuk-table__header--active", text: "Email")
          .and have_no_selector(".govuk-table__header--active", text: "Questions")
      end

      it "orders the users correctly when the sort param is '-last_login_at'" do
        create(:early_access_user, email: "a@example.com", last_login_at: 1.hour.ago)
        create(:early_access_user, email: "b@example.com", last_login_at: 1.day.ago)
        create(:early_access_user, email: "c@example.com", last_login_at: 1.minute.ago)

        get admin_early_access_users_path(sort: "-last_login_at")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/c@example\.com.*a@example\.com.*b@example\.com/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is '-last_login_at'" do
        create(:early_access_user)

        get admin_early_access_users_path(sort: "-last_login_at")

        expect(response.body)
          .to have_link("Last login", href: admin_early_access_users_path(sort: "last_login_at"))
          .and have_link("Questions", href: admin_early_access_users_path(sort: "-questions_count"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--descending", text: "Last login")
          .and have_link("Email", href: admin_early_access_users_path(sort: "email"))
          .and have_no_selector(".govuk-table__header--active", text: "Email")
          .and have_no_selector(".govuk-table__header--active", text: "Questions")
      end

      it "orders the users correctly when the sort param is 'email'" do
        create(:early_access_user, email: "a@example.com")
        create(:early_access_user, email: "c@example.com")
        create(:early_access_user, email: "b@example.com")

        get admin_early_access_users_path(sort: "email")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/a@example\.com.*b@example\.com.*c@example\.com/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is 'email'" do
        create(:early_access_user)

        get admin_early_access_users_path(sort: "email")

        expect(response.body)
          .to have_link("Email", href: admin_early_access_users_path(sort: "-email"))
          .and have_link("Questions", href: admin_early_access_users_path(sort: "-questions_count"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--ascending", text: "Email")
          .and have_link("Last login", href: admin_early_access_users_path(sort: "-last_login_at"))
          .and have_no_selector(".govuk-table__header--active", text: "Last login")
          .and have_no_selector(".govuk-table__header--active", text: "Questions")
      end

      it "orders the users correctly when the sort param is '-email'" do
        create(:early_access_user, email: "a@example.com")
        create(:early_access_user, email: "c@example.com")
        create(:early_access_user, email: "b@example.com")

        get admin_early_access_users_path(sort: "-email")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/c@example\.com.*b@example\.com.*a@example\.com/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is '-email'" do
        create(:early_access_user)

        get admin_early_access_users_path(sort: "-email")

        expect(response.body)
          .to have_link("Email", href: admin_early_access_users_path(sort: "email"))
          .and have_link("Questions", href: admin_early_access_users_path(sort: "-questions_count"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--descending", text: "Email")
          .and have_link("Last login", href: admin_early_access_users_path(sort: "-last_login_at"))
          .and have_no_selector(".govuk-table__header--active", text: "Last login")
          .and have_no_selector(".govuk-table__header--active", text: "Questions")
      end

      it "orders the users correctly when the sort param is 'questions_count'" do
        create(:early_access_user, email: "a@example.com", questions_count: 2)
        create(:early_access_user, email: "c@example.com", questions_count: 0)
        create(:early_access_user, email: "b@example.com", questions_count: 1)

        get admin_early_access_users_path(sort: "questions_count")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/c@example\.com.*b@example\.com.*a@example\.com/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is 'questions_count'" do
        create(:early_access_user)

        get admin_early_access_users_path(sort: "questions_count")

        expect(response.body)
          .to have_link("Email", href: admin_early_access_users_path(sort: "email"))
          .and have_link("Questions", href: admin_early_access_users_path(sort: "-questions_count"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--ascending", text: "Questions")
          .and have_link("Last login", href: admin_early_access_users_path(sort: "-last_login_at"))
          .and have_no_selector(".govuk-table__header--active", text: "Last login")
          .and have_no_selector(".govuk-table__header--active", text: "Email")
      end

      it "orders the users correctly when the sort param is '-questions_count'" do
        create(:early_access_user, email: "a@example.com", questions_count: 0)
        create(:early_access_user, email: "c@example.com", questions_count: 2)
        create(:early_access_user, email: "b@example.com", questions_count: 1)

        get admin_early_access_users_path(sort: "-questions_count")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/c@example\.com.*b@example\.com.*a@example\.com/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is '-questions_count'" do
        create(:early_access_user)

        get admin_early_access_users_path(sort: "-questions_count")

        expect(response.body)
          .to have_link("Email", href: admin_early_access_users_path(sort: "email"))
          .and have_link("Questions", href: admin_early_access_users_path(sort: "questions_count"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--descending", text: "Questions")
          .and have_link("Last login", href: admin_early_access_users_path(sort: "-last_login_at"))
          .and have_no_selector(".govuk-table__header--active", text: "Last login")
          .and have_no_selector(".govuk-table__header--active", text: "Email")
      end
    end
  end

  describe "GET :show" do
    it "renders the user details" do
      user = create(
        :early_access_user,
        email: "alice@example.com",
        last_login_at: Time.zone.parse("2024-1-1 12:13:14"),
        login_count: 12,
        user_description: :business_owner_or_self_employed,
        reason_for_visit: :find_specific_answer,
        found_chat: :govuk_website,
        revoked_at: nil,
        individual_question_limit: 0,
        questions_count: 7,
      )

      get admin_early_access_user_path(user)

      ur_question_text = %i[user_description reason_for_visit found_chat].each_with_object({}) do |question, memo|
        options = Rails.configuration.pilot_user_research_questions[question.to_s].options
        option = options.find { |o| o.value == user.public_send(question) }
        memo[question] = option.fetch("text")
      end

      expect(response.body)
        .to have_content("User details")
        .and have_content("alice@example.com")
        .and have_content("12:13pm on 1 January 2024")
        .and have_content(ur_question_text[:user_description])
        .and have_content(ur_question_text[:reason_for_visit])
        .and have_content(ur_question_text[:found_chat])
        .and have_content("Unlimited")
        .and have_content("12")
        .and have_link("7", href: admin_questions_path(user_id: user.id))
    end

    it "renders the links to manage the user" do
      user = create(:early_access_user)

      get admin_early_access_user_path(user)

      expect(response.body)
        .to have_link("Edit user", href: edit_admin_early_access_user_path(user))
        .and have_link("Delete user", href: delete_admin_early_access_user_path(user))
    end

    it "renders the revoked details" do
      user = create(
        :early_access_user,
        revoked_at: Time.zone.parse("2024-1-2 09:10:11"),
        revoked_reason: "Asking too many questions",
      )

      get admin_early_access_user_path(user)

      expect(response.body)
        .to have_content("9:10am on 2 January 2024")
        .and have_content("Asking too many questions")
    end
  end

  describe "GET :new" do
    it "renders the form" do
      get new_admin_early_access_user_path
      expect(response).to have_http_status(:ok)

      expect(response.body).to have_content("New early access user")
    end
  end

  describe "POST :create" do
    it "creates a new user and redirects" do
      post admin_early_access_users_path, params: { create_early_access_user_form: { email: "new.user@example.com" } }

      expect(EarlyAccessUser.last).to have_attributes(
        email: "new.user@example.com",
        source: "admin_added",
      )
      expect(response).to redirect_to(admin_early_access_user_path(EarlyAccessUser.last))
    end

    it "renders the form with errors" do
      post admin_early_access_users_path, params: { create_early_access_user_form: { email: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to have_content("Enter an email address")
    end
  end

  describe "GET :edit" do
    it "renders the form" do
      get edit_admin_early_access_user_path(create(:early_access_user))

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_content("Edit early access user")
        .and have_content("Question limit")
    end

    it "renders the input field with the default value if is is null" do
      user = create(:early_access_user, individual_question_limit: nil)
      get edit_admin_early_access_user_path(user)

      default_limit = Rails.configuration.conversations.max_questions_per_user

      expect(response.body)
        .to have_selector("input[id=update_early_access_user_form_question_limit][value=#{default_limit}]")
    end
  end

  describe "PATCH :update" do
    it "updates the user and redirects" do
      user = create(:early_access_user, individual_question_limit: 2)

      patch admin_early_access_user_path(user),
            params: {
              update_early_access_user_form: {
                question_limit: 3,
              },
            }

      expect(user.reload).to have_attributes(
        individual_question_limit: 3,
      )

      expect(response).to redirect_to(admin_early_access_user_path(user))
    end

    it "renders the form with errors" do
      user = create(:early_access_user)

      patch admin_early_access_user_path(user),
            params: {
              update_early_access_user_form: {
                question_limit: "invalid",
              },
            }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to have_content("Question limit must be a number or blank")
    end
  end

  describe "GET :delete" do
    it "renders the delete confirmation page" do
      user = create(:early_access_user)

      get delete_admin_early_access_user_path(user)

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_content("Are you sure you want to delete this user?")
        .and have_content("Revoke access instead")
    end
  end

  describe "DELETE :destroy" do
    it "deletes the user and redirects" do
      user = create(:early_access_user)

      expect { delete admin_early_access_user_path(user) }
        .to change(EarlyAccessUser, :count).by(-1)

      expect(EarlyAccessUser.find_by_id(user.id)).to be_nil

      expect(response).to redirect_to(admin_early_access_users_path)
    end

    it "creates a DeletedEarlyAccessUser with 'admin' as deletion_type and records the admin id" do
      user = create(:early_access_user)
      admin_user = create(:admin_user, :admin)
      login_as(admin_user)

      expect { delete admin_early_access_user_path(user) }
      .to change { DeletedEarlyAccessUser.where(deletion_type: :admin).count }.by(1)

      expect(DeletedEarlyAccessUser.last.deleted_by_admin_user_id).to eq admin_user.id
    end

    it "keeps the user's conversations" do
      user = create(:early_access_user)
      conversation = create(:conversation, :with_history, user:)
      questions = conversation.questions

      delete admin_early_access_user_path(user)

      existing_record = Conversation.find_by_id(conversation.id)
      expect(existing_record).not_to be_nil
      expect(existing_record.questions.count).to eq(questions.count)
    end
  end
end
