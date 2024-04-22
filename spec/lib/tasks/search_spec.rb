RSpec.describe "rake search tasks" do
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

    it "delegates the task to Search::ChunkedContentRepository" do
      repo = instance_double(Search::ChunkedContentRepository, create_index!: nil)
      allow(Search::ChunkedContentRepository).to receive(:new).and_return(repo)

      Rake::Task[task_name].invoke

      expect(repo).to have_received(:create_index!)
    end

    it "is prevented from running in Rails.env.production?" do
      allow(Rails.env).to receive(:production?).and_return(true)

      expect { Rake::Task[task_name].invoke }
        .to output("This task has been disabled for production environments\n").to_stdout
        .and raise_error(SystemExit)
    end
  end
end
