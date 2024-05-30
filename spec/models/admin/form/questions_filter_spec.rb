RSpec.describe Admin::Form::QuestionsFilter do
  describe "#questions" do
    it "orders the questions by the most recently created" do
      question1 = create(:question, created_at: 2.minutes.ago)
      question2 = create(:question, created_at: 1.minute.ago)

      questions = described_class.new.questions

      expect(questions).to eq([question2, question1])
    end

    it "filters the questions by search" do
      question1 = create(:question, message: "hello world", created_at: 1.minute.ago)
      question2 = create(:question, created_at: 2.minutes.ago)
      create(:answer, message: "hello moon", question: question2)
      question3 = create(:question, created_at: 3.minutes.ago)
      create(:answer, rephrased_question: "Hello Stars", question: question3)
      create(:question, message: "goodbye")

      questions = described_class.new(search: "hello").questions
      expect(questions).to eq([question1, question2, question3])
    end

    it "filters the questions by status" do
      question1 = create(:question)
      question2 = create(:answer, status: "success").question

      questions = described_class.new(status: "pending").questions
      expect(questions).to eq([question1])

      questions = described_class.new(status: "success").questions
      expect(questions).to eq([question2])
    end

    it "works with all filters applied" do
      question = create(:answer, status: "success", message: "hello world").question
      questions = described_class.new(status: "success", search: "Hello").questions
      expect(questions).to eq([question])
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

        questions = described_class.new(conversation: question1.conversation).questions

        expect(questions).to eq([question1])
      end
    end
  end

  describe "previous_page_params" do
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
      create_list(:question, 26)
      filter = described_class.new(status: "pending", search: "message", page: 2)
      expect(filter.previous_page_params).to eq({ status: "pending", search: "message" })
    end
  end

  describe "next_page_params" do
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
      create_list(:question, 26)
      filter = described_class.new(status: "pending", search: "message")
      expect(filter.next_page_params).to eq({ status: "pending", search: "message", page: 2 })
    end
  end
end
