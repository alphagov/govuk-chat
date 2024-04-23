RSpec.describe Search::ChunkedContentRepository, :chunked_content_index do
  let(:repository) { described_class.new }

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
    let(:chunked_content_records) do
      [
        build(:chunked_content_record, openai_embedding:),
        build(:chunked_content_record),
        build(:chunked_content_record),
      ]
    end

    before do
      populate_chunked_content_index(chunked_content_records)
    end

    it "returns an array of Result objects where the score is over #{described_class::MIN_SCORE}" do
      result = repository.search_by_embedding(openai_embedding)
      expected_attributes = chunked_content_records.first.except(:openai_embedding).merge(score: 1)

      expect(result).to all be_a(Search::ChunkedContentRepository::Result)
      expect(result).to all have_attributes(score: a_value > described_class::MIN_SCORE)
      expect(result.first).to have_attributes(**expected_attributes)
    end

    context "when there are more then the maxiumum number of results" do
      let(:chunked_content_records) { build_list(:chunked_content_record, described_class::MAX_CHUNKS + 1, openai_embedding:) }

      it "only returns the first #{described_class::MAX_CHUNKS}" do
        result = repository.search_by_embedding(openai_embedding)
        expect(result.count).to eq described_class::MAX_CHUNKS
      end
    end
  end
end
