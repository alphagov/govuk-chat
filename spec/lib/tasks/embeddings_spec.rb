RSpec.describe "rake embeddings tasks", :chunked_content_index do
  describe "embeddings:generate_titan" do
    let(:task_name) { "embeddings:generate_titan" }
    let(:documents) do
      [
        build(:chunked_content_record, plain_content: "Content 1", titan_embedding: nil),
        build(:chunked_content_record, plain_content: "Content 2", titan_embedding: mock_titan_embedding("Content 2")),
        build(:chunked_content_record, plain_content: "Content 3", titan_embedding: nil),
      ]
    end

    before do
      Rake::Task[task_name].reenable

      populate_chunked_content_index({
        "id1" => documents[0],
        "id2" => documents[1],
        "id3" => documents[2],
      })

      stub_bedrock_titan_embedding("Content 1")
      stub_bedrock_titan_embedding("Content 3")
    end

    it "outputs a count of documents missing the titan_embedding field" do
      expect { Rake::Task[task_name].invoke }
        .to output(/Documents missing titan_embedding field: 2/).to_stdout
    end

    it "generates Titan embeddings for documents without existing embeddings" do
      expect(GenerateTextEmbeddingJob).to receive(:perform_later).with("id1")
      expect(GenerateTextEmbeddingJob).to receive(:perform_later).with("id3")
      expect(GenerateTextEmbeddingJob).not_to receive(:perform_later).with("id2")

      expect { Rake::Task[task_name].invoke }.to output.to_stdout
    end
  end
end
