RSpec.describe "rake search tasks" do
  shared_examples "disabled in Rails.env.production?" do
    it "is prevented from running in Rails.env.production?" do
      allow(Rails.env).to receive(:production?).and_return(true)

      expect { Rake::Task[task_name].invoke }
        .to output("This task has been disabled for production environments\n").to_stdout
        .and raise_error(SystemExit)
    end
  end

  describe "search:create_chunked_content_index" do
    let(:task_name) { "search:create_chunked_content_index" }
    let(:repo) { instance_double(Search::ChunkedContentRepository, create_index: nil) }

    before do
      Rake::Task[task_name].reenable
      allow(Search::ChunkedContentRepository).to receive(:new).and_return(repo)
    end

    it "delegates the task to Search::ChunkedContentRepository" do
      expect { Rake::Task[task_name].invoke }.to output.to_stdout

      expect(repo).to have_received(:create_index)
    end

    it "outputs progress information to stdout" do
      expect { Rake::Task[task_name].invoke }
        .to output("Creating chunked content index\nIndex created\n").to_stdout
    end

    # This test relied on the :chunked_content_index tag creating the index
    it "gracefully handles the index already existing", :chunked_content_index do
      allow(Search::ChunkedContentRepository).to receive(:new).and_call_original

      expect { Rake::Task[task_name].invoke }
        .to output(/Index already exists/).to_stdout
    end
  end

  describe "search:recreate_chunked_content_index" do
    let(:task_name) { "search:recreate_chunked_content_index" }

    before { Rake::Task[task_name].reenable }

    it_behaves_like "disabled in Rails.env.production?"

    it "delegates the task to Search::ChunkedContentRepository" do
      repo = instance_double(Search::ChunkedContentRepository, create_index!: nil)
      allow(Search::ChunkedContentRepository).to receive(:new).and_return(repo)

      expect { Rake::Task[task_name].invoke }.to output.to_stdout

      expect(repo).to have_received(:create_index!)
    end

    it "outputs progress information to stdout" do
      expect { Rake::Task[task_name].invoke }
        .to output("Recreating chunked content index\nIndex created\n").to_stdout
    end
  end

  describe "search:populate_chunked_content_index_from_seeds", :chunked_content_index do
    let(:task_name) { "search:populate_chunked_content_index_from_seeds" }
    let(:seed_data) do
      glob_path = Rails.root.join("db/chunked_content_seeds/*.yml")
      Dir[glob_path].flat_map { |file| YAML.load_file(file) }
    end
    let(:repository) { Search::ChunkedContentRepository.new }

    before do
      Rake::Task[task_name].reenable

      allow(Search::TextToEmbedding::Titan).to receive(:call) do |arg|
        arg.map { |a| mock_titan_embedding(a) }
      end
    end

    it_behaves_like "disabled in Rails.env.production?"

    it "populates the chunked_content_index outputting the number of chunks it adds" do
      expected_chunks = seed_data.flat_map { |seed| seed["chunks"] }.count

      expect { Rake::Task[task_name].invoke }
        .to change { repository.count(match_all: {}) }
        .and output(/#{expected_chunks} chunks indexed/).to_stdout
    end

    it "deletes the chunked_content_index outputting the number of chunks it adds" do
      populate_chunked_content_index(
        "id1" => build(:chunked_content_record, base_path: seed_data.dig(0, "base_path")),
        "id2" => build(:chunked_content_record, base_path: seed_data.dig(1, "base_path")),
      )

      expect { Rake::Task[task_name].invoke }
        .to change { repository.count(ids: { values: %w[id1 id2] }) }.by(-2)
        .and output(/2 conflicting chunks deleted/).to_stdout
    end

    it "runs search:create_chunked_content_index as a prerequisite" do
      expect(Rake::Task[task_name].prereqs).to include("create_chunked_content_index")
    end
  end

  describe "search:update_chunked_content_mappings" do
    let(:task_name) { "search:update_chunked_content_mappings" }
    let(:repository) { Search::ChunkedContentRepository.new }

    before do
      Rake::Task[task_name].reenable
      allow(Search::ChunkedContentRepository).to receive(:new).and_return(repository)
    end

    it "delegates the task to Search::ChunkedContentRepository" do
      allow(repository).to receive(:update_missing_mappings)

      expect { Rake::Task[task_name].invoke }.to output.to_stdout
      expect(repository).to have_received(:update_missing_mappings)
    end

    it "outputs information about missing mappings to stoud" do
      allow(repository).to receive(:update_missing_mappings).and_return(%i[parent_document_type child_document_type])
      expect { Rake::Task[task_name].invoke }
        .to output("Adding missing content mappings\nMapping(s) added for:\ parent_document_type, child_document_type\n").to_stdout
    end

    it "outputs that no mappings were updated if none were missing" do
      allow(repository).to receive(:update_missing_mappings).and_return([])
      expect { Rake::Task[task_name].invoke }
      .to output("Adding missing content mappings\nNo mappings were added\n").to_stdout
    end
  end

  describe "search:backfill_answer_source_chunks", :chunked_content_index do
    let(:task_name) { "search:backfill_answer_source_chunks" }

    before { Rake::Task[task_name].reenable }

    it "updates answer_source_chunk records that have a search result with a matching digest" do
      match_chunk, not_match_chunk = create_list(:answer_source_chunk, 2, document_type: "")

      field_updates = {
        heading_hierarchy: ["Updated Heading"],
        html_content: "<h1>Updated HTML</h1>",
        plain_content: "Updated plain content",
        document_type: "updated_document_type",
        parent_document_type: "updated_document_type",
        description: "Updated description",
      }

      matched_result = build(
        :chunked_content_record,
        **field_updates.merge(match_chunk.attributes.slice(*%w[content_id locale chunk_index digest])),
      )
      not_matched_result = build(
        :chunked_content_record,
        **field_updates.merge(not_match_chunk.attributes.slice(*%w[content_id locale chunk_index])),
      )

      matched_id = [match_chunk.content_id, match_chunk.locale, match_chunk.chunk_index].join("_")
      not_matched_id = [not_match_chunk.content_id, not_match_chunk.locale, not_match_chunk.chunk_index].join("_")

      populate_chunked_content_index(matched_id => matched_result, not_matched_id => not_matched_result)

      expect { Rake::Task[task_name].invoke }
        .to output("Finished - Checked 2 records - updated 1, out of date 1, not found 0\n").to_stdout

      expect(match_chunk.reload).to have_attributes(field_updates)
      expect(not_match_chunk.reload).not_to have_attributes(field_updates)
    end

    it "doesn't update answer_source_chunk records where a search result can't be found" do
      create(:answer_source_chunk, document_type: "")

      expect { Rake::Task[task_name].invoke }
        .to output("Finished - Checked 1 records - updated 0, out of date 0, not found 1\n").to_stdout
    end

    it "doesn't update answer_source_chunk records that have a document_type" do
      create(:answer_source_chunk, document_type: "news_article")

      expect { Rake::Task[task_name].invoke }
        .to output("Finished - Checked 0 records - updated 0, out of date 0, not found 0\n").to_stdout
    end
  end
end
