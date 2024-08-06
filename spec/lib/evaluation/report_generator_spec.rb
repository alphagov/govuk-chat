RSpec.describe Evaluation::ReportGenerator, :chunked_content_index do
  let(:evaluation_questions) { ["How do I pay VAT?", "Do I need a visa?"] }

  let(:answers) do
    [
      build(
        :answer,
        message: "First answer from OpenAI",
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
            title: "Pay your VAT bill online", content_chunk_id: "id1", content_chunk_digest: "digest1",
          ),
        ],
      ),
      build(
        :answer,
        message: "Second answer from OpenAI",
        sources: [
          build(:answer_source, title: "Check if you need a visa", content_chunk_id: "id3", content_chunk_digest: "digest3"),
        ],
      ),
    ]
  end

  before do
    allow(described_class).to receive(:evaluation_questions).and_return(evaluation_questions)

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

  describe ".evaluation_questions" do
    it "loads the questions from the YAML file" do
      questions = described_class.evaluation_questions
      expect(questions).to be_an(Array)
      expect(questions.map(&:class).uniq).to eq([String])
    end
  end

  describe ".call" do
    it "returns the items" do
      items = described_class.call

      expect(items).to match([
        {
          question: "How do I pay VAT?",
          llm_answer: "First answer from OpenAI",
          retrieved_context: [
            hash_including(title: "Late payments"),
            hash_including(title: "Pay your VAT bill online"),
          ],
        },
        {
          question: "Do I need a visa?",
          llm_answer: "Second answer from OpenAI",
          retrieved_context: [hash_including(title: "Check if you need a visa")],
        },
      ])
    end

    it "builds retrieved context items" do
      items = described_class.call
      context = items.first[:retrieved_context].first

      expect(context).to eq({
        title: "Late payments",
        heading_hierarchy: ["VAT", "Late payments"],
        description: "Paying your VAT bill",
        html_content: "<p>Some content</p>",
        exact_path: "https://www.test.gov.uk/vat-payments/late-payments",
        base_path: "https://www.test.gov.uk/vat-payments",
      })
    end

    context "when the content chunk cannot be found" do
      let(:answers) do
        [build(:answer, sources: [build(:answer_source, content_chunk_id: "id999")])]
      end

      it "includes an error in the retrieved_context" do
        items = described_class.call
        context = items.first[:retrieved_context].first

        expect(context).to include(error: "Could not find content chunk")
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

      it "includes an error in the retrieved_context" do
        items = described_class.call
        context = items.first[:retrieved_context].first

        expect(context).to include(error: "Content chunk digest mismatch")
      end
    end

    it "yields the progress" do
      expect { |block| described_class.call(&block) }.to yield_successive_args(
        [2, 1, "How do I pay VAT?"],
        [2, 2, "Do I need a visa?"],
      )
    end
  end
end
