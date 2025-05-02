RSpec.describe Admin::Filters::QuestionsFilter do
  describe "validations" do
    describe "#validate_dates" do
      it "is valid if the start date and end date are valid dates" do
        filter = described_class.new(
          start_date_params: { day: "1", month: "1", year: "2020" },
          end_date_params: { day: "1", month: "1", year: "2020" },
        )
        expect(filter).to be_valid
      end

      it "is valid with blank params" do
        filter = described_class.new(
          start_date_params: { day: "", month: "", year: "" },
          end_date_params: { day: "", month: "", year: "" },
        )
        expect(filter).to be_valid
      end

      it "is invalid if the start date is not a valid date" do
        filter = described_class.new(
          start_date_params: { day: "1", month: "13", year: "2020" },
          end_date_params: { day: "1", month: "1", year: "2020" },
        )
        expect(filter).not_to be_valid
        expect(filter.errors[:start_date_params]).to eq(["Enter a valid start date"])
      end

      it "is invalid if the end date is not a valid date" do
        filter = described_class.new(
          start_date_params: { day: "1", month: "1", year: "2020" },
          end_date_params: { day: "32", month: "1", year: "2020" },
        )
        expect(filter).not_to be_valid
        expect(filter.errors[:end_date_params]).to eq(["Enter a valid end date"])
      end

      it "is invalid with partial date params" do
        filter = described_class.new(
          start_date_params: { day: "1", month: "1" },
          end_date_params: { day: "1", month: "1" },
        )

        expect(filter).not_to be_valid
        expect(filter.errors[:start_date_params]).to eq(["Enter a valid start date"])
        expect(filter.errors[:end_date_params]).to eq(["Enter a valid end date"])
      end
    end
  end

  describe "#initialize" do
    it "validates on initialisation" do
      filter = described_class.new(
        start_date_params: { day: "1", month: "13", year: "2020" },
        end_date_params: { day: "32", month: "1", year: "2020" },
      )

      expect(filter.errors[:start_date_params]).to eq(["Enter a valid start date"])
      expect(filter.errors[:end_date_params]).to eq(["Enter a valid end date"])
    end

    it "sets the sort param to the default value if no value is passed in" do
      filter = described_class.new
      expect(filter.sort).to eq("-created_at")
    end

    it "sets the sort param to the default value if an invalid value is passed in" do
      filter = described_class.new(sort: "invalid")
      expect(filter.sort).to eq("-created_at")
    end
  end

  describe "#results" do
    describe "ordering" do
      let!(:question_1_min_ago) { create(:question, message: "Hello world", created_at: 1.minute.ago) }
      let!(:question_2_mins_ago) { create(:question, :with_answer, message: "World hello", created_at: 2.minutes.ago) }
      let!(:question_3_mins_ago) { create(:question, :with_answer, message: "Sup moon", created_at: 3.minutes.ago) }

      it "orders the results by the most recently created" do
        results = described_class.new.results
        expect(results).to eq([question_1_min_ago, question_2_mins_ago, question_3_mins_ago])
      end

      it "orders the results by the most recently created when the sort param is '-created_at'" do
        results = described_class.new(sort: "-created_at").results
        expect(results).to eq([question_1_min_ago, question_2_mins_ago, question_3_mins_ago])
      end

      it "orders the results by the most recently created if the sort param is invalid" do
        results = described_class.new(sort: "invalid").results
        expect(results).to eq([question_1_min_ago, question_2_mins_ago, question_3_mins_ago])
      end

      it "orders the results by the oldest first when the sort param is 'created_at'" do
        results = described_class.new(sort: "created_at").results
        expect(results).to eq([question_3_mins_ago, question_2_mins_ago, question_1_min_ago])
      end

      it "orders the results alphabetically when the sort param is 'message'" do
        results = described_class.new(sort: "message").results
        expect(results).to eq([question_1_min_ago, question_3_mins_ago, question_2_mins_ago])
      end

      it "orders the results reverse alphabetically when the sort param is '-message'" do
        results = described_class.new(sort: "-message").results
        expect(results).to eq([question_2_mins_ago, question_3_mins_ago, question_1_min_ago])
      end
    end

    it "filters the results by search" do
      question1 = create(:question, message: "hello world", created_at: 1.minute.ago)
      question2 = create(:question, created_at: 2.minutes.ago)
      create(:answer, message: "hello moon", question: question2)
      question3 = create(:question, created_at: 3.minutes.ago)
      create(:answer, rephrased_question: "Hello Stars", question: question3)
      create(:question, message: "goodbye")

      filter = described_class.new(search: "hello")
      expect(filter.results).to eq([question1, question2, question3])
    end

    it "filters the results by status" do
      question1 = create(:question)
      question2 = create(:answer, status: "answered").question

      filter = described_class.new(status: "pending")
      expect(filter.results).to eq([question1])

      filter = described_class.new(status: "answered")
      expect(filter.results).to eq([question2])
    end

    it "filters the results by start date" do
      question = create(:question)
      create(:question, created_at: 2.days.ago)
      today = Date.current
      filter = described_class.new(
        start_date_params: { day: today.day, month: today.month, year: today.year },
      )

      expect(filter.results).to eq([question])
    end

    it "filters the results by end date" do
      question = create(:question, created_at: 2.days.ago)
      create(:question)

      today = Date.current
      filter = described_class.new(end_date_params: { day: today.day, month: today.month, year: today.year })

      expect(filter.results).to eq([question])
    end

    it "does not filter on the start date when start date is invalid" do
      question = create(:question, created_at: 2.years.ago)
      create(:question)

      today = Date.current
      filter = described_class.new(
        start_date_params: { day: today.day, month: "invalid", year: today.year },
        end_date_params: { day: today.day, month: today.month, year: today.year - 1 },
      )

      expect(filter.results).to eq([question])
    end

    it "does not filter on the end date when end date is invalid" do
      create(:question, created_at: 2.years.ago)
      question = create(:question)

      today = Date.current
      filter = described_class.new(
        start_date_params: { day: today.day, month: today.month, year: today.year - 1 },
        end_date_params: { day: today.day, month: "invalid", year: today.year },
      )

      expect(filter.results).to eq([question])
    end

    it "filters the results between the start and end dates" do
      question = create(:question, created_at: 3.years.ago)
      create(:question, created_at: 1.year.ago)
      create(:question, created_at: 5.years.ago)

      today = Date.current
      filter = described_class.new(
        start_date_params: { day: today.day, month: today.month, year: today.year - 4 },
        end_date_params: { day: today.day, month: today.month, year: today.year - 2 },
      )

      expect(filter.results).to eq([question])
    end

    it "filters the results by answer feedback" do
      useful_question = create(:question)
      answer1 = create(:answer, question: useful_question)
      create(:answer_feedback, answer: answer1, useful: true)

      useless_question = create(:question)
      answer2 = create(:answer, question: useless_question)
      create(:answer_feedback, answer: answer2, useful: false)

      filter = described_class.new(answer_feedback_useful: "true")
      expect(filter.results).to eq([useful_question])

      filter = described_class.new(answer_feedback_useful: "false")
      expect(filter.results).to eq([useless_question])
    end

    it "filters the results by user" do
      alice = create(:early_access_user, email: "alice@example.com")
      bob = create(:early_access_user, email: "bob@example.com")
      alice_question = create(:question, conversation: create(:conversation, user: alice))
      bob_question = create(:question, conversation: create(:conversation, user: bob))

      filter = described_class.new(user_id: alice.id)
      expect(filter.results).to eq([alice_question])

      filter = described_class.new(user_id: bob.id)
      expect(filter.results).to eq([bob_question])
    end

    it "filters the results by signon user" do
      alice = create(:signon_user, email: "alice@example.com")
      bob = create(:signon_user, email: "bob@example.com")
      alice_question = create(:question, conversation: create(:conversation, signon_user: alice))
      bob_question = create(:question, conversation: create(:conversation, signon_user: bob))

      filter = described_class.new(signon_user_id: alice.id)
      expect(filter.results).to eq([alice_question])

      filter = described_class.new(signon_user_id: bob.id)
      expect(filter.results).to eq([bob_question])
    end

    it "doesn't filter the results by signon user if signon_user_id and user_id are passed in" do
      alice = create(:signon_user, email: "alice@example.com")
      bob = create(:early_access_user, email: "bob@example.com")
      create(:question, conversation: create(:conversation, signon_user: alice))
      bob_question = create(:question, conversation: create(:conversation, user: bob))

      filter = described_class.new(signon_user_id: alice.id, user_id: bob.id)
      expect(filter.results).to eq([bob_question])
    end

    it "filters the results by question routing label" do
      create(:question, answer: build(:answer, question_routing_label: "genuine_rag"))
      non_english_question = create(:question, answer: build(:answer, question_routing_label: "non_english"))

      filter = described_class.new(question_routing_label: "non_english")
      expect(filter.results).to eq([non_english_question])
    end

    it "paginates the results" do
      create_list(:question, 26)

      questions = described_class.new(page: 1).results
      expect(questions.count).to eq(25)

      questions = described_class.new(page: 2).results
      expect(questions.count).to eq(1)
    end

    context "when a conversation_id is passed in on initilisation" do
      it "scopes the results to the conversation" do
        question1 = create(:question, created_at: 2.minutes.ago)
        create(:question, created_at: 1.minute.ago)

        filter = described_class.new(conversation_id: question1.conversation_id)

        expect(filter.results).to eq([question1])
      end
    end
  end

  it_behaves_like "a paginatable filter", :question

  describe "#previous_page_params" do
    it "retains all other query params when constructing the params" do
      user = create(:early_access_user)
      conversation = create(:conversation, user:)
      26.times do
        question = create(:question, conversation:)
        create(:answer, :with_feedback, question:)
      end
      today = Date.current
      start_date_params = { day: today.day, month: today.month, year: today.year - 1 }
      end_date_params = { day: today.day, month: today.month, year: today.year + 1 }

      filter = described_class.new(
        status: "answered",
        search: "message",
        page: 2,
        start_date_params:,
        end_date_params:,
        answer_feedback_useful: "true",
        user_id: user.id,
        conversation_id: conversation.id,
      )

      expect(filter.previous_page_params)
        .to eq(
          {
            status: "answered",
            search: "message",
            answer_feedback_useful: true,
            start_date_params:,
            end_date_params:,
            user_id: user.id,
            conversation_id: conversation.id,
          },
        )
    end
  end

  describe "#next_page_params" do
    it "retains all other query params when constructing the params" do
      user = create(:early_access_user)
      conversation = create(:conversation, user:)
      26.times do
        question = create(:question, conversation:)
        create(:answer, :with_feedback, question:)
      end
      today = Date.current
      start_date_params = { day: today.day, month: today.month, year: today.year - 1 }
      end_date_params = { day: today.day, month: today.month, year: today.year + 1 }

      filter = described_class.new(
        status: "answered",
        search: "message",
        start_date_params:,
        end_date_params:,
        answer_feedback_useful: "true",
        user_id: user.id,
        conversation_id: conversation.id,
      )

      expect(filter.next_page_params)
        .to eq(
          {
            status: "answered",
            search: "message",
            answer_feedback_useful: true,
            page: 2,
            start_date_params:,
            end_date_params:,
            user_id: user.id,
            conversation_id: conversation.id,
          },
        )
    end
  end

  it_behaves_like "a sortable filter", "created_at"
end
