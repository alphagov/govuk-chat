RSpec.describe AnswerComposition::Pipeline::Context do
  describe "#initialize" do
    it "builds an answer object from the question" do
      question = build(:question)
      instance = described_class.new(question)

      expect(instance.answer)
        .to be_a(Answer)
        .and have_attributes(question:)
    end

    it "sets the question_message based on the question" do
      question = build(:question, message: "What is the current VAT rate?")
      instance = described_class.new(question)
      expect(instance.question_message).to eq("What is the current VAT rate?")
    end

    it "sets an initial aborted status of false" do
      instance = described_class.new(build(:question))
      expect(instance).not_to be_aborted
    end
  end

  describe "#abort_pipeline" do
    it "changes the aborted status" do
      instance = described_class.new(build(:question))
      instance.abort_pipeline
      expect(instance).to be_aborted
    end

    it "returns the answer" do
      instance = described_class.new(build(:question))
      expect(instance.abort_pipeline).to be(instance.answer)
    end

    it "accepts arguments to update the answer model" do
      instance = described_class.new(build(:question))
      args = { message: "answer", status: "success" }
      instance.abort_pipeline(**args)
      expect(instance.answer).to have_attributes(args)
    end
  end

  describe "#abort_pipeline!" do
    it "throws an abort symbol" do
      instance = described_class.new(build(:question))
      expect { instance.abort_pipeline! }.to throw_symbol(:abort)
    end

    it "delegates to #abort_pipeline" do
      instance = described_class.new(build(:question))
      args = { message: "answer", status: "success" }
      allow(instance).to receive(:abort_pipeline)
      expect { instance.abort_pipeline!(**args) }.to throw_symbol(:abort)
      expect(instance).to have_received(:abort_pipeline).with(args)
    end
  end

  describe "#question_message=" do
    it "updates the question_message attribute" do
      instance = described_class.new(build(:question))
      instance.question_message = "Next question?"

      expect(instance.question_message).to eq("Next question?")
    end

    context "when the question_message is same as the question message" do
      it "resets answer.rephrased_question" do
        instance = described_class.new(build(:question, message: "First question"))

        instance.question_message = "First question"
        expect(instance.answer.rephrased_question).to be_nil
      end
    end

    context "when the question_message is different to the question's message" do
      it "updates answer.rephrased_question to question_message" do
        instance = described_class.new(build(:question, message: "First question"))

        instance.question_message = "Rephrased question"
        expect(instance.answer.rephrased_question).to eq("Rephrased question")
      end
    end
  end

  describe "#search_results=" do
    let(:search_results) { build_list(:chunked_content_search_result, 2) }

    it "updates the search_results attribute" do
      instance = described_class.new(build(:question))
      instance.search_results = search_results

      expect(instance.search_results).to eq(search_results)
    end

    it "builds sources on the answer by delegating to answers method" do
      instance = described_class.new(build(:question))

      expect { instance.search_results = search_results }
        .to change { instance.answer.sources.length }.from(0)
    end
  end
end
