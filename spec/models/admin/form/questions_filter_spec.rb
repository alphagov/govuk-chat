RSpec.describe Admin::Form::QuestionsFilter do
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

  describe "#questions" do
    describe "ordering" do
      let!(:question_1_min_ago) { create(:question, message: "Hello world", created_at: 1.minute.ago) }
      let!(:question_2_mins_ago) { create(:question, :with_answer, message: "World hello", created_at: 2.minutes.ago) }
      let!(:question_3_mins_ago) { create(:question, :with_answer, message: "Sup moon", created_at: 3.minutes.ago) }

      it "orders the questions by the most recently created" do
        questions = described_class.new.questions
        expect(questions).to eq([question_1_min_ago, question_2_mins_ago, question_3_mins_ago])
      end

      it "orders the questions by the most recently created when the sort param is '-created_at'" do
        questions = described_class.new(sort: "-created_at").questions
        expect(questions).to eq([question_1_min_ago, question_2_mins_ago, question_3_mins_ago])
      end

      it "orders the questions by the most recently created if the sort param is invalid" do
        questions = described_class.new(sort: "invalid").questions
        expect(questions).to eq([question_1_min_ago, question_2_mins_ago, question_3_mins_ago])
      end

      it "orders the questions by the oldest first when the sort param is 'created_at'" do
        questions = described_class.new(sort: "created_at").questions
        expect(questions).to eq([question_3_mins_ago, question_2_mins_ago, question_1_min_ago])
      end

      it "orders the questions alphabetically when the sort param is 'message'" do
        questions = described_class.new(sort: "message").questions
        expect(questions).to eq([question_1_min_ago, question_3_mins_ago, question_2_mins_ago])
      end

      it "orders the questions reverse alphabetically when the sort param is '-message'" do
        questions = described_class.new(sort: "-message").questions
        expect(questions).to eq([question_2_mins_ago, question_3_mins_ago, question_1_min_ago])
      end
    end

    it "filters the questions by search" do
      question1 = create(:question, message: "hello world", created_at: 1.minute.ago)
      question2 = create(:question, created_at: 2.minutes.ago)
      create(:answer, message: "hello moon", question: question2)
      question3 = create(:question, created_at: 3.minutes.ago)
      create(:answer, rephrased_question: "Hello Stars", question: question3)
      create(:question, message: "goodbye")

      filter = described_class.new(search: "hello")
      expect(filter.questions).to eq([question1, question2, question3])
    end

    it "filters the questions by status" do
      question1 = create(:question)
      question2 = create(:answer, status: "success").question

      filter = described_class.new(status: "pending")
      expect(filter.questions).to eq([question1])

      filter = described_class.new(status: "success")
      expect(filter.questions).to eq([question2])
    end

    it "filters the questions by start date" do
      question = create(:question)
      create(:question, created_at: 2.days.ago)
      today = Date.current
      filter = described_class.new(
        start_date_params: { day: today.day, month: today.month, year: today.year },
      )

      expect(filter.questions).to eq([question])
    end

    it "filters the questions by end date" do
      question = create(:question, created_at: 2.days.ago)
      create(:question)

      today = Date.current
      filter = described_class.new(end_date_params: { day: today.day, month: today.month, year: today.year })

      expect(filter.questions).to eq([question])
    end

    it "does not filter on the start date when start date is invalid" do
      question = create(:question, created_at: 2.years.ago)
      create(:question)

      today = Date.current
      filter = described_class.new(
        start_date_params: { day: today.day, month: "invalid", year: today.year },
        end_date_params: { day: today.day, month: today.month, year: today.year - 1 },
      )

      expect(filter.questions).to eq([question])
    end

    it "does not filter on the end date when end date is invalid" do
      create(:question, created_at: 2.years.ago)
      question = create(:question)

      today = Date.current
      filter = described_class.new(
        start_date_params: { day: today.day, month: today.month, year: today.year - 1 },
        end_date_params: { day: today.day, month: "invalid", year: today.year },
      )

      expect(filter.questions).to eq([question])
    end

    it "filters the questions between the start and end dates" do
      question = create(:question, created_at: 3.years.ago)
      create(:question, created_at: 1.year.ago)
      create(:question, created_at: 5.years.ago)

      today = Date.current
      filter = described_class.new(
        start_date_params: { day: today.day, month: today.month, year: today.year - 4 },
        end_date_params: { day: today.day, month: today.month, year: today.year - 2 },
      )

      expect(filter.questions).to eq([question])
    end

    it "filters the questions by answer feedback" do
      useful_question = create(:question)
      answer1 = create(:answer, question: useful_question)
      create(:answer_feedback, answer: answer1, useful: true)

      useless_question = create(:question)
      answer2 = create(:answer, question: useless_question)
      create(:answer_feedback, answer: answer2, useful: false)

      filter = described_class.new(answer_feedback_useful: "true")
      expect(filter.questions).to eq([useful_question])

      filter = described_class.new(answer_feedback_useful: "false")
      expect(filter.questions).to eq([useless_question])
    end

    it "paginates the questions" do
      create_list(:question, 26)

      questions = described_class.new(page: 1).questions
      expect(questions.count).to eq(25)

      questions = described_class.new(page: 2).questions
      expect(questions.count).to eq(1)
    end

    context "when a conversation is passed in on initilisation" do
      it "scopes the questions to the conversation" do
        question1 = create(:question, created_at: 2.minutes.ago)
        create(:question, created_at: 1.minute.ago)

        filter = described_class.new(conversation: question1.conversation)

        expect(filter.questions).to eq([question1])
      end
    end
  end

  describe "#previous_page_params" do
    it "returns any empty hash if there is no previous page to link to" do
      filter = described_class.new
      expect(filter.previous_page_params).to eq({})
    end

    it "constructs the previous pages url based on the path passed in when a previous page is present" do
      create_list(:question, 51)
      filter = described_class.new(page: 3)
      expect(filter.previous_page_params).to eq({ page: 2 })
    end

    it "removes the page param from the url correctly when it links to the first page of questions" do
      create_list(:question, 26)
      filter = described_class.new(page: 2)
      expect(filter.previous_page_params).to eq({})
    end

    it "retains all other query params when constructing the params" do
      create_list(:answer, 26, :with_feedback)
      today = Date.current
      start_date_params = { day: today.day, month: today.month, year: today.year - 1 }
      end_date_params = { day: today.day, month: today.month, year: today.year + 1 }

      filter = described_class.new(
        status: "success",
        search: "message",
        page: 2,
        start_date_params:,
        end_date_params:,
        answer_feedback_useful: "true",
      )

      expect(filter.previous_page_params)
        .to eq({ status: "success", search: "message", answer_feedback_useful: true, start_date_params:, end_date_params: })
    end
  end

  describe "#next_page_params" do
    it "returns any empty hash if there is no next page to link to" do
      filter = described_class.new
      expect(filter.next_page_params).to eq({})
    end

    it "constructs the next page based on the path passed in when a next page is present" do
      create_list(:question, 26)
      filter = described_class.new(page: 1)
      expect(filter.next_page_params).to eq({ page: 2 })
    end

    it "retains all other query params when constructing the params" do
      create_list(:answer, 26, :with_feedback)
      today = Date.current
      start_date_params = { day: today.day, month: today.month, year: today.year - 1 }
      end_date_params = { day: today.day, month: today.month, year: today.year + 1 }

      filter = described_class.new(
        status: "success",
        search: "message",
        start_date_params:,
        end_date_params:,
        answer_feedback_useful: "true",
      )

      expect(filter.next_page_params)
        .to eq({ status: "success", search: "message", answer_feedback_useful: true, page: 2, start_date_params:, end_date_params: })
    end
  end

  describe "#sort_direction" do
    it "returns nil when sort does not match the field passed in" do
      filter = described_class.new(sort: "message")
      expect(filter.sort_direction("created_at")).to be_nil
    end

    it "returns 'ascending' when sort equals the field passed in" do
      filter = described_class.new(sort: "message")
      expect(filter.sort_direction("message")).to eq("ascending")
    end

    it "returns 'descending' when sort prefixed with '-' equals the field passed in" do
      filter = described_class.new(sort: "-message")
      expect(filter.sort_direction("message")).to eq("descending")
    end
  end

  describe "#toggleable_sort_params" do
    it "sets the page param to nil" do
      filter = described_class.new(sort: "-created_at", page: 2)
      expect(filter.toggleable_sort_params("-created_at")).to eq({ sort: "created_at", page: nil })
    end

    context "when the sort attribute does not match the default_field_sort" do
      it "sets the sort_param to the default_field_sort" do
        filter = described_class.new(sort: "created_at")
        expect(filter.toggleable_sort_params("-created_at")).to eq({ sort: "-created_at", page: nil })
      end
    end

    context "when the sort attribute matches the default_field_sort" do
      it "sets the sort_param to 'ascending' if the sort attribute is 'descending'" do
        filter = described_class.new(sort: "-created_at")
        expect(filter.toggleable_sort_params("-created_at")).to eq({ sort: "created_at", page: nil })
      end

      it "sets the sort_param to 'descending' if the sort attribute is 'ascending'" do
        filter = described_class.new(sort: "message")
        expect(filter.toggleable_sort_params("message")).to eq({ sort: "-message", page: nil })
      end
    end
  end
end
