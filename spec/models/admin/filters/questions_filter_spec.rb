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

    it "filters the results by conversation source" do
      question1 = create(:question)
      question2 = create(:question, conversation: build(:conversation, :api))

      filter = described_class.new(source: "web")
      expect(filter.results).to eq([question1])

      filter = described_class.new(source: "api")
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

    it "filters the results by signon user" do
      alice = create(:signon_user, email: "alice@example.com")
      bob = create(:signon_user, email: "bob@example.com")
      alice_question = create(:question, conversation: create(:conversation, signon_user: alice))
      bob_question_created_via_api = create(:question, conversation: create(:conversation, :api, signon_user: bob))
      bob_question_created_via_web = create(:question, conversation: create(:conversation, signon_user: bob))

      filter = described_class.new(signon_user_id: alice.id)
      expect(filter.results).to eq([alice_question])

      filter = described_class.new(signon_user_id: bob.id)
      expect(filter.results).to contain_exactly(bob_question_created_via_api, bob_question_created_via_web)
    end

    it "filters the results by end_user_id" do
      alice_question = create(:question, conversation: create(:conversation, :api, end_user_id: "alice"))
      bob_question = create(:question, conversation: create(:conversation, :api, end_user_id: "bob"))

      filter = described_class.new(end_user_id: "alice")
      expect(filter.results).to eq([alice_question])

      filter = described_class.new(end_user_id: "bob")
      expect(filter.results).to eq([bob_question])
    end

    it "filters out results associated with an end_user_id that weren't created via the API" do
      create(:question, conversation: create(:conversation, end_user_id: "alice"))

      filter = described_class.new(end_user_id: "alice")

      expect(filter.results).to eq([])
    end

    it "filters the results by conversation_session_id" do
      alice_question = create(:question)
      create(:question)

      filter = described_class.new(conversation_session_id: alice_question.conversation_session_id)
      expect(filter.results).to eq([alice_question])
    end

    it "filters the results by question routing label" do
      create(:question, answer: build(:answer, question_routing_label: "genuine_rag"))
      non_english_question = create(:question, answer: build(:answer, question_routing_label: "non_english"))

      filter = described_class.new(question_routing_label: "non_english")
      expect(filter.results).to eq([non_english_question])
    end

    it "filters the results by primary topic" do
      business_answer = build(:answer, topics: build(:answer_analysis_topics, primary_topic: "business"))
      business_question = create(:question, answer: business_answer)
      tax_answer = build(:answer, topics: build(:answer_analysis_topics, primary_topic: "tax"))
      tax_question = create(:question, answer: tax_answer)

      filter = described_class.new(primary_topic: "business")
      expect(filter.results).to eq([business_question])

      filter = described_class.new(primary_topic: "tax")
      expect(filter.results).to eq([tax_question])
    end

    it "filters the results by secondary topic" do
      business_answer = build(:answer, topics: build(:answer_analysis_topics, secondary_topic: "business"))
      business_question = create(:question, answer: business_answer)
      tax_answer = build(:answer, topics: build(:answer_analysis_topics, secondary_topic: "tax"))
      tax_question = create(:question, answer: tax_answer)

      filter = described_class.new(secondary_topic: "business")
      expect(filter.results).to eq([business_question])

      filter = described_class.new(secondary_topic: "tax")
      expect(filter.results).to eq([tax_question])
    end

    it "filters the results by completeness" do
      complete_answer = create(:answer, completeness: "complete")
      complete_question = create(:question, answer: complete_answer)
      partial_answer = create(:answer, completeness: "partial")
      partial_question = create(:question, answer: partial_answer)
      no_info_answer = create(:answer, completeness: "no_information")
      no_info_question = create(:question, answer: no_info_answer)

      filter = described_class.new(completeness: "complete")
      expect(filter.results).to eq([complete_question])

      filter = described_class.new(completeness: "partial")
      expect(filter.results).to eq([partial_question])

      filter = described_class.new(completeness: "no_information")
      expect(filter.results).to eq([no_info_question])
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

  describe "#signon_user" do
    it "returns the signon_user if signon_user_id is passed in" do
      signon_user = create(:signon_user)
      filter = described_class.new(signon_user_id: signon_user.id)

      expect(filter.signon_user).to eq(signon_user)
    end

    it "returns nil if signon_user_id is not passed in" do
      filter = described_class.new
      expect(filter.signon_user).to be_nil
    end

    it "returns nil if signon_user_id is passed in but the signon_user does not exist" do
      filter = described_class.new(signon_user_id: "invalid_id")
      expect(filter.signon_user).to be_nil
    end
  end

  describe "#conversation" do
    it "returns the conversation if conversation_id is passed in" do
      conversation = create(:conversation)
      filter = described_class.new(conversation_id: conversation.id)

      expect(filter.conversation).to eq(conversation)
    end

    it "returns nil if conversation_id is not passed in" do
      filter = described_class.new
      expect(filter.conversation).to be_nil
    end

    it "returns nil if conversation_id is passed in but the conversation does not exist" do
      filter = described_class.new(conversation_id: "invalid_id")
      expect(filter.conversation).to be_nil
    end
  end

  it_behaves_like "a paginatable filter", :question

  describe "#previous_page_params" do
    it "retains all other query params when constructing the params" do
      filter = create_paginatable_filter({ page: 2 })

      expected_params = filter.attributes
                              .symbolize_keys
                              .except(:page, :answer_feedback_useful)
                              .merge(answer_feedback_useful: true)
      expect(filter.previous_page_params).to eq(expected_params)
    end
  end

  describe "#next_page_params" do
    it "retains all other query params when constructing the params" do
      today = Date.current
      start_date_params = { day: today.day, month: today.month, year: today.year - 1 }
      end_date_params = { day: today.day, month: today.month, year: today.year + 1 }

      filter = create_paginatable_filter({ start_date_params:, end_date_params: })

      expected_params = filter.attributes
                              .symbolize_keys
                              .except(:answer_feedback_useful)
                              .merge(answer_feedback_useful: true, page: 2)
      expect(filter.next_page_params).to eq(expected_params)
    end
  end

  def create_paginatable_filter(attrs = {})
    signon_user = create(:signon_user)
    conversation = create(:conversation, signon_user_id: signon_user.id, end_user_id: "end-user-id", source: :api)
    conversation_session_id = SecureRandom.uuid
    26.times do
      question = create(:question, conversation:, conversation_session_id:)
      answer = create(
        :answer,
        :with_feedback,
        question:,
        question_routing_label: "vague_acronym_grammar",
        completeness: "complete",
      )
      create(:answer_analysis_topics, answer:, primary_topic: "business", secondary_topic: "tax")
    end

    today = Date.current
    start_date_params = { day: today.day, month: today.month, year: today.year - 1 }
    end_date_params = { day: today.day, month: today.month, year: today.year + 1 }

    filter_params = {
      status: "answered",
      search: "message",
      sort: "created_at",
      source: "api",
      start_date_params:,
      end_date_params:,
      answer_feedback_useful: "true",
      conversation_id: conversation.id,
      signon_user_id: signon_user.id,
      end_user_id: "end-user-id",
      question_routing_label: "vague_acronym_grammar",
      primary_topic: "business",
      secondary_topic: "tax",
      completeness: "complete",
      conversation_session_id:,
    }.merge(attrs)

    described_class.new(**filter_params)
  end

  it_behaves_like "a sortable filter", "created_at"
end
