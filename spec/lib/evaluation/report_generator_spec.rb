RSpec.describe Evaluation::ReportGenerator do
  let(:evaluation_questions) { ["How do I pay VAT?", "Do I need a visa?"] }
  let(:input_file) do
    temp_file = Tempfile.new
    temp_file.write(evaluation_questions.to_yaml)
    temp_file.close
    temp_file
  end

  let(:answers) do
    [
      build(
        :answer,
        message: "First answer",
        sources: [
          build(
            :answer_source,
            chunk: build(:answer_source_chunk, title: "Late payments"),
          ),
          build(
            :answer_source,
            chunk: build(:answer_source_chunk, title: "Pay your VAT bill online"),
          ),
          build(
            :answer_source,
            used: false,
            chunk: build(:answer_source_chunk, title: "Unused source"),
          ),
        ],
      ),
      build(
        :answer,
        message: "Second answer",
        sources: [
          build(
            :answer_source,
            chunk: build(:answer_source_chunk, title: "Check if you need a visa"),
          ),
        ],
      ),
    ]
  end

  before do
    allow(AnswerComposition::Composer).to receive(:call).and_return(*answers)
  end

  after { input_file.unlink }

  describe ".call" do
    it "raises an error if the file does not exist" do
      expect { described_class.call("nonexistent.yml") }
        .to raise_error("File nonexistent.yml does not exist")
    end

    it "uses the configured answer strategy" do
      allow(Rails.configuration).to receive(:answer_strategy).and_return("claude_structured_answer")

      described_class.call(input_file.path)

      expect(AnswerComposition::Composer).to have_received(:call).with(
        an_object_having_attributes(answer_strategy: "claude_structured_answer"),
      ).twice
    end

    it "returns the items" do
      items = described_class.call(input_file.path)

      expect(items).to match([
        {
          question: "How do I pay VAT?",
          answer: hash_including("message" => "First answer"),
          answer_strategy: Rails.configuration.answer_strategy,
          retrieved_context: [
            hash_including(used: true, chunk: hash_including(title: "Late payments")),
            hash_including(used: true, chunk: hash_including(title: "Pay your VAT bill online")),
            hash_including(used: false, chunk: hash_including(title: "Unused source")),
          ],
        },
        {
          question: "Do I need a visa?",
          answer: hash_including("message" => "Second answer"),
          answer_strategy: Rails.configuration.answer_strategy,
          retrieved_context: [
            hash_including(used: true, chunk: hash_including(title: "Check if you need a visa")),
          ],
        },
      ])
    end

    it "builds retrieved context items" do
      items = described_class.call(input_file.path)
      context = items.first[:retrieved_context].first

      chunk = answers.first.sources.first.chunk

      expect(context).to match({
        search_score: an_instance_of(Float),
        weighted_score: an_instance_of(Float),
        used: true,
        chunk: chunk.as_json(except: %i[id updated_at created_at]).symbolize_keys,
      })
    end

    it "returns all the answer fields except ones written on DB persistence" do
      items = described_class.call(input_file.path)
      answer_data = items.first[:answer]
      expected_answer_data = answers.first.as_json(except: %i[id question_id created_at updated_at])

      expect(answer_data).to match(expected_answer_data)
    end

    it "yields the progress" do
      expect { |block| described_class.call(input_file.path, &block) }.to yield_successive_args(
        [2, 1, "How do I pay VAT?"],
        [2, 2, "Do I need a visa?"],
      )
    end
  end
end
