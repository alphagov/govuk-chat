RSpec.describe Evaluation::ReportGenerator, :chunked_content_index do
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
            title: "Late payments",
            content_chunk_id: "id2",
            content_chunk_digest: "digest2",
            exact_path: "/vat-payments/late-payments",
            base_path: "/vat-payments",
          ),
          build(
            :answer_source,
            title: "Pay your VAT bill online",
            content_chunk_id: "id1",
            content_chunk_digest: "digest1",
          ),
          build(
            :answer_source,
            title: "Unused source",
            used: false,
          ),
        ],
      ),
      build(
        :answer,
        message: "Second answer",
        sources: [
          build(:answer_source, title: "Check if you need a visa", content_chunk_id: "id3", content_chunk_digest: "digest3"),
        ],
      ),
    ]
  end

  before do
    populate_chunked_content_index({
      "id1" => build(
        :chunked_content_record,
        description: "Paying your VAT bill",
        digest: "digest1",
        heading_hierarchy: %w[VAT],
      ),
      "id2" => build(
        :chunked_content_record,
        description: "Paying your VAT bill",
        digest: "digest2",
        heading_hierarchy: ["VAT", "Late payments"],
      ),
      "id3" => build(
        :chunked_content_record,
        description: "Visa requirements",
        digest: "digest3",
        heading_hierarchy: %w[Visas],
      ),
    })

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
            hash_including(title: "Late payments", used: true),
            hash_including(title: "Pay your VAT bill online", used: true),
            hash_including(title: "Unused source", used: false),
          ],
        },
        {
          question: "Do I need a visa?",
          answer: hash_including("message" => "Second answer"),
          answer_strategy: Rails.configuration.answer_strategy,
          retrieved_context: [hash_including(title: "Check if you need a visa", used: true)],
        },
      ])
    end

    it "builds retrieved context items" do
      items = described_class.call(input_file.path)
      context = items.first[:retrieved_context].first

      expect(context).to eq({
        title: "Late payments",
        used: true,
        exact_path: "/vat-payments/late-payments",
        base_path: "/vat-payments",
        content_chunk_id: "id2",
        content_chunk_available: true,
        heading_hierarchy: ["VAT", "Late payments"],
        description: "Paying your VAT bill",
        html_content: "<p>Some content</p>",
      })
    end

    it "returns all the answer fields except ones written on DB persistence" do
      items = described_class.call(input_file.path)
      answer_data = items.first[:answer]
      expected_answer_data = answers.first.as_json(except: %i[id question_id created_at updated_at])

      expect(answer_data).to match(expected_answer_data)
    end

    context "when the content chunk cannot be found" do
      let(:answers) do
        [build(:answer, sources: [build(:answer_source, content_chunk_id: "id999")])]
      end

      it "marks the chunk as unavailable" do
        items = described_class.call(input_file.path)
        context = items.first[:retrieved_context].first

        expect(context).to include(
          content_chunk_id: "id999",
          content_chunk_available: false,
        )
      end
    end

    context "when the content chunk digest does not match" do
      let(:answers) do
        [
          build(:answer, sources: [
            build(:answer_source, content_chunk_id: "id1", content_chunk_digest: "abc"),
          ]),
        ]
      end

      it "marks the content chunk as unavailable" do
        items = described_class.call(input_file.path)
        context = items.first[:retrieved_context].first

        expect(context).to include(
          content_chunk_id: "id1",
          content_chunk_available: false,
        )
      end
    end

    it "yields the progress" do
      expect { |block| described_class.call(input_file.path, &block) }.to yield_successive_args(
        [2, 1, "How do I pay VAT?"],
        [2, 2, "Do I need a visa?"],
      )
    end
  end
end
