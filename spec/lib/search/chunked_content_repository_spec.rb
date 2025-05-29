RSpec.describe Search::ChunkedContentRepository, :chunked_content_index do
  let(:repository) { described_class.new }

  describe "#create_index" do
    let(:client) { repository.client }

    before do
      allow(client.indices).to receive(:create)
    end

    it "creates a new index with an alias" do
      repository.create_index

      expected_args = {
        index: repository.default_index_name,
        body: {
          settings: {
            index: {
              knn: true,
            },
          },
          mappings: {
            properties: described_class::MAPPINGS,
          },
          aliases: { "#{repository.index}": {} },
        },
      }
      expect(client.indices).to have_received(:create).with(**expected_args)
    end

    it "takes an optional index name" do
      repository.create_index(index_name: "custom_index")

      expected_args = {
        index: "custom_index",
        body: {
          settings: {
            index: {
              knn: true,
            },
          },
          mappings: {
            properties: described_class::MAPPINGS,
          },
          aliases: { "#{repository.index}": {} },
        },
      }
      expect(client.indices).to have_received(:create).with(**expected_args)
    end

    it "does not create an alias if create_alias is false" do
      repository.create_index(index_name: "custom_index", create_alias: false)

      expected_args = {
        index: "custom_index",
        body: {
          settings: {
            index: {
              knn: true,
            },
          },
          mappings: {
            properties: described_class::MAPPINGS,
          },
          aliases: {},
        },
      }
      expect(client.indices).to have_received(:create).with(**expected_args)
    end
  end

  describe "#create_index!" do
    let(:client) { repository.client }

    before do
      allow(client.indices).to receive(:create)
    end

    it "deletes a pre-existing index before creating a new one" do
      allow(client.indices).to receive(:delete)
      repository.create_index!

      expect(client.indices).to have_received(:delete).with(index: repository.default_index_name)
    end

    it "delegates to create with default args when none are present" do
      allow(repository).to receive(:create_index)
      repository.create_index!

      expect(repository).to have_received(:create_index).with(index_name: repository.default_index_name, create_alias: true)
    end

    it "delegates to create and retains the index name and alias boolean when present" do
      allow(repository).to receive(:create_index)
      repository.create_index!(index_name: "custom_index", create_alias: false)

      expect(repository).to have_received(:create_index).with(index_name: "custom_index", create_alias: false)
    end
  end

  describe "#delete_by_base_path" do
    before do
      populate_chunked_content_index([
        build(:chunked_content_record, base_path: "/a"),
        build(:chunked_content_record, base_path: "/a"),
        build(:chunked_content_record, base_path: "/b"),
      ])
    end

    it "deletes all items of a particular base_path" do
      expect { repository.delete_by_base_path("/a") }
        .to change { repository.count(term: { base_path: "/a" }) }
        .by(-2)
    end

    it "returns the number of items it deleted" do
      expect(repository.delete_by_base_path("/a")).to eq(2)
    end
  end

  describe "#delete_by_id" do
    before do
      populate_chunked_content_index(
        "id1" => build(:chunked_content_record, base_path: "/a"),
        "id2" => build(:chunked_content_record, base_path: "/a"),
        "id3" => build(:chunked_content_record, base_path: "/b"),
      )
    end

    it "can delete a single document by id" do
      expect { repository.delete_by_id("id1") }
        .to change { repository.count(term: { base_path: "/a" }) }
        .by(-1)
    end

    it "can delete multiple documents by an array of ids" do
      expect { repository.delete_by_id(%w[id1 id2]) }
        .to change { repository.count(term: { base_path: "/a" }) }
        .by(-2)
    end

    it "returns the number of documents deleted" do
      expect(repository.delete_by_id(%w[id1 id2])).to eq(2)
    end

    it "doesn't raise an error if there are no documents to delete" do
      result = nil
      expect { result = repository.delete_by_id(%w[id4 id5]) }
        .not_to raise_error
      expect(result).to eq(0)
    end
  end

  describe "#index_document" do
    it "can add a new document to the index" do
      expect { repository.index_document("id1", { base_path: "/a" }) }
        .to change { repository.count(term: { base_path: "/a" }) }
        .by(1)
    end

    it "can replace an existing document in the index" do
      populate_chunked_content_index("id1" => build(:chunked_content_record, base_path: "/a", document_type: "news_story"))

      expect { repository.index_document("id1", { base_path: "/b" }) }
        .to change { repository.count(term: { base_path: "/b" }) }
        .by(1)
        .and change { repository.count(term: { document_type: "news_story" }) }
        .by(-1)
    end

    it "returns :created when adding content" do
      expect(repository.index_document("id1", { base_path: "/b" })).to eq(:created)
    end

    it "returns :updated when updating content" do
      populate_chunked_content_index("id1" => build(:chunked_content_record, base_path: "/a"))
      expect(repository.index_document("id1", { base_path: "/b" })).to eq(:updated)
    end
  end

  describe "#id_digest_hash" do
    before do
      populate_chunked_content_index(
        "id1" => build(:chunked_content_record, base_path: "/a", digest: "000"),
        "id2" => build(:chunked_content_record, base_path: "/a", digest: "111"),
        "id3" => build(:chunked_content_record, base_path: "/a", digest: "222"),
        "id4" => build(:chunked_content_record, base_path: "/b", digest: "333"),
        "id5" => build(:chunked_content_record, base_path: "/b", digest: "444"),
      )
    end

    it "returns a hash of items matching a particular base_path" do
      expect(repository.id_digest_hash("/b")).to match({
        "id4" => "333",
        "id5" => "444",
      })
    end

    it "can paginate through results if there are more items than the batch size" do
      expect(repository.id_digest_hash("/a", batch_size: 1)).to match({
        "id1" => "000",
        "id2" => "111",
        "id3" => "222",
      })
    end
  end

  describe "#search_by_embedding" do
    let(:openai_embedding) { mock_openai_embedding("How do i pay my tax?") }
    let(:titan_embedding) { mock_titan_embedding("How do i get universal credit?") }
    let(:chunked_content_records) do
      [
        build(:chunked_content_record, openai_embedding:, titan_embedding:),
        build(:chunked_content_record),
        build(:chunked_content_record),
      ]
    end

    before do
      populate_chunked_content_index(chunked_content_records)
    end

    it "returns an array of Result objects for OpenAI embedding" do
      result = repository.search_by_embedding(
        openai_embedding,
        max_chunks: 10,
        llm_provider: :openai,
      )
      expected_attributes = chunked_content_records.first
                                                   .except(:openai_embedding, :titan_embedding)
                                                   .merge(score: a_value_between(0.9, 1))

      expect(result).to all be_a(Search::ChunkedContentRepository::Result)
      expect(result.first).to have_attributes(**expected_attributes)
    end

    it "returns an array of Result objects for Titan embedding" do
      result = repository.search_by_embedding(
        titan_embedding,
        max_chunks: 10,
        llm_provider: :titan,
      )
      expected_attributes = chunked_content_records.first
                                                   .except(:titan_embedding, :openai_embedding)
                                                   .merge(score: a_value_between(0.9, 1))

      expect(result).to all be_a(Search::ChunkedContentRepository::Result)
      expect(result.first).to have_attributes(**expected_attributes)
    end

    it "raises an error if the llm provider is not recognised" do
      expect {
        repository.search_by_embedding(
          openai_embedding,
          max_chunks: 10,
          llm_provider: :unknown,
        )
      }.to raise_error("Unknown provider: unknown")
    end

    context "when there are more than the maxiumum chunks" do
      let(:max_chunks) { 10 }
      let(:chunked_content_records) { build_list(:chunked_content_record, 11, openai_embedding:) }

      it "only returns the first max_chunks" do
        result = repository.search_by_embedding(
          openai_embedding,
          max_chunks:,
          llm_provider: :openai,
        )
        expect(result.count).to eq max_chunks
      end
    end
  end

  describe "#chunk" do
    let(:content_chunk) { build :chunked_content_record }
    let(:chunk_id) { "chunk_id" }

    before do
      populate_chunked_content_index({ chunk_id => content_chunk })
    end

    it "returns the correct chunk as a ChunkedContentRepository::Result" do
      chunk_result = repository.chunk(chunk_id)
      expect(chunk_result).to be_a(Search::ChunkedContentRepository::Result)
        .and have_attributes(content_chunk.except(:openai_embedding, :titan_embedding))
        .and have_attributes(_id: chunk_id)
    end

    it "raises ChunkedContentRepository::NotFound when the id does not exist in the index" do
      expect { repository.chunk("does not exist") }.to raise_error(
        an_instance_of(Search::ChunkedContentRepository::NotFound)
          .and(having_attributes(message: "_id: 'does not exist' is not in the 'govuk_chat_chunked_content_test' index",
                                 cause: an_instance_of(OpenSearch::Transport::Transport::Errors::NotFound))),
      )
    end
  end

  describe "#update_missing_mappings", chunked_content_index: false do
    let(:index) { repository.index }

    it "updates the index with any missing mappings" do
      original_mappings = described_class::MAPPINGS
      stub_const("Search::ChunkedContentRepository::MAPPINGS", {})
      repository.create_index!
      stub_const("Search::ChunkedContentRepository::MAPPINGS", original_mappings)

      result = repository.update_missing_mappings

      new_mappings = repository
                     .client
                     .indices
                     .get_mapping(index:)
                     .dig(repository.default_index_name, "mappings", "properties")
                     .deep_symbolize_keys

      expect(result).to eq(original_mappings.keys)
      expect(new_mappings.keys.sort).to eq(original_mappings.keys.sort)
    end

    it "returns an empty array if no mappings are missing" do
      repository.create_index!
      result = repository.update_missing_mappings
      expect(result).to eq([])
    end
  end
end
