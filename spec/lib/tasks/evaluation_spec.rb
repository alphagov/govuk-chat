RSpec.describe "rake evaluation tasks" do
  describe "generate_report" do
    let(:task_name) { "evaluation:generate_report" }
    let(:evaluation_data) do
      [
        { question: "First question", llm_answer: "First answer" },
        { question: "Second question", llm_answer: "Second answer" },
      ]
    end
    let(:jsonl) do
      evaluation_data.map(&:to_json).join("\n")
    end

    before do
      Rake::Task[task_name].reenable

      allow(Evaluation::ReportGenerator).to receive(:call).and_return(evaluation_data)
    end

    it "generates the results as JSONL and prints them" do
      expect { Rake::Task[task_name].invoke }
        .to output(/#{jsonl}/).to_stdout
    end

    it "generates the results as JSONL and writes them to a file" do
      temp = Tempfile.new
      path = temp.path

      begin
        expect { Rake::Task[task_name].invoke(path) }
          .to output(/Written to #{path}/).to_stdout

        expect(File.read(path)).to eq(jsonl)
      ensure
        temp.close
        temp.unlink
      end
    end
  end
end
