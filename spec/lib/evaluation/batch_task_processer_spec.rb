RSpec.describe Evaluation::BatchTaskProcesser do
  describe ".call" do
    def populate_input_file(input_file, questions)
      input_file.open
      # clear existing file contents
      input_file.truncate(0)
      input_file.write(questions.to_yaml)
      input_file.close
    end

    let(:evaluation_questions) { ["How do I pay VAT?", "Do I need a visa?"] }
    let(:input_file) do
      Tempfile.new.tap { |t| populate_input_file(t, evaluation_question) }
    end

    let(:process_status) { instance_double(Process::Status, exitstatus: 0) }

    before do
      allow(Open3)
        .to receive(:capture3)
        .and_return([{ "simple" => "json" }.to_json, "", process_status])
    end

    after { input_file.unlink }

    it "runs an evaluation rake task for each question in the input YAML file" do
      described_class.call(input_file.path, "my_task", [])

      expect(Open3)
        .to have_received(:capture3)
        .with(anything, "bundle", "exec", "rake", "evaluation:my_task[]")
        .exactly(evaluation_questions.count).times
    end

    it "returns an array of results containing JSON of input and output" do
      results = described_class.call(input_file.path, "my_task", [])

      expect(results).to eq([
        { "input" => evaluation_questions[0], "output" => { "simple" => "json" } },
        { "input" => evaluation_questions[1], "output" => { "simple" => "json" } },
      ])
    end

    it "raises an error if the input YAML file doesn't exist" do
      expect { described_class.call("non-existent.yaml", "my_task", []) }
        .to raise_error("File non-existent.yaml does not exist")
    end

    it "spawns a number of threads equal to the concurrency parameter" do
      populate_input_file(input_file, Array.new(50) { "Question" })

      allow(Thread).to receive(:new).and_call_original

      described_class.call(input_file.path, "my_task", [], concurrency: 20)

      expect(Thread).to have_received(:new).exactly(20).times
    end

    it "doesn't spawn more threads than questions" do
      populate_input_file(input_file, Array.new(7) { "Question" })

      allow(Thread).to receive(:new).and_call_original

      described_class.call(input_file.path, "my_task", [], concurrency: 20)

      expect(Thread).to have_received(:new).exactly(7).times
    end

    describe "running rake task" do
      it "passes the question as an INPUT env var to the task" do
        described_class.call(input_file.path, "my_task", [])

        task = ["bundle", "exec", "rake", "evaluation:my_task[]"]

        expect(Open3)
          .to have_received(:capture3)
          .with(hash_including("INPUT" => evaluation_questions[0]), *task)

        expect(Open3)
          .to have_received(:capture3)
          .with(hash_including("INPUT" => evaluation_questions[1]), *task)
      end

      it "passes arguments to the task" do
        described_class.call(input_file.path, "my_task", %w[arg1 arg2])

        expect(Open3)
          .to have_received(:capture3)
          .with(anything, "bundle", "exec", "rake", "evaluation:my_task[arg1, arg2]")
          .at_least(1).time
      end

      it "escapes task arguments" do
        described_class.call(input_file.path, "my_task", ["$complex", '"argu", "ments"'])
        task_args = ["bundle",
                     "exec",
                     "rake",
                     "evaluation:my_task[\\$complex, \\\"argu\\\",\\ \\\"ments\\\"]"]

        expect(Open3)
          .to have_received(:capture3)
          .with(anything, *task_args)
          .at_least(1).time
      end

      it "copes if the task name provided is prefixed with evaluation:" do
        described_class.call(input_file.path, "evaluation:my_task", [])

        expect(Open3)
          .to have_received(:capture3)
          .with(anything, "bundle", "exec", "rake", "evaluation:my_task[]")
          .at_least(1).time
      end

      it "raises an error if the task returns a non zero status code" do
        allow(process_status).to receive(:exitstatus).and_return(1)

        stderr_output = "Error\nMore Information\n"

        allow(Open3)
          .to receive(:capture3)
          .and_return(["", stderr_output, process_status])

        error_message = "Task failed for question \"#{evaluation_questions[0]}\":\n\n#{stderr_output}"

        expect { described_class.call(input_file.path, "my_task", []) }
          .to raise_error(error_message)
          .and output.to_stderr # Threads, unless configured otherwise, default to writing errors to stderr
      end
    end

    context "when passed a block" do
      it "invokes the block for each question with progress counts" do
        questions = ["Question 1", "Question 2", "Question 3"]
        populate_input_file(input_file, questions)

        expected_yields = [
          [anything, 3, 1],
          [anything, 3, 2],
          [anything, 3, 3],
        ]

        expect { |b| described_class.call(input_file.path, "my_task", [], &b) }
          .to yield_successive_args(*expected_yields)
      end

      it "includes warnings raised from the task stderr, separated by new lines" do
        stderr_output_1 = "Warning on first item\nMore information\n"
        stderr_output_2 = "Another warning"

        allow(Open3)
          .to receive(:capture3)
          .and_return(["{}", stderr_output_1, process_status],
                      ["{}", stderr_output_2, process_status])

        expected_yields = [
          [["Warning on first item", "More information"], Integer, Integer],
          [["Another warning"], Integer, Integer],
        ]

        expect { |b| described_class.call(input_file.path, "my_task", [], &b) }
          .to yield_successive_args(*expected_yields)
      end

      it "only includes distinct, non empty, warnings that haven't already been seen" do
        allow(Open3)
          .to receive(:capture3)
          .and_return(["{}", "Warning\n\n", process_status])

        expected_yields = [
          [%w[Warning], Integer, Integer],
          [[], Integer, Integer],
        ]

        expect { |b| described_class.call(input_file.path, "my_task", [], &b) }
          .to yield_successive_args(*expected_yields)
      end

      it "removes repetitive warnings like the prometheus server start" do
        questions = ["Question 1"]
        populate_input_file(input_file, questions)

        allow(Open3)
          .to receive(:capture3)
          .and_return(["{}", "not starting Prometheus metrics server: address already in use", process_status])

        expect { |b| described_class.call(input_file.path, "my_task", [], &b) }
          .to yield_with_args([], Integer, Integer)
      end
    end
  end
end
