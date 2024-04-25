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

      allow(Search::TextToEmbedding).to receive(:call) do |arg|
        arg.map { |a| mock_openai_embedding(a) }
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
end
