RSpec.describe OpenAIClient do # rubocop:disable RSpec/FilePath
  describe ".build" do
    let(:chat_parameters) do
      {
        model: "gpt-3.5-turbo",
        messages: [{ role: "user", content: "Hello!" }],
      }
    end

    it "returns an OpenAI::Client instance" do
      expect(described_class.build).to be_an_instance_of(OpenAI::Client)
    end

    it "configures the client to not write to stdout when an error occurs" do
      stub_request(:post, /openai\.com/).to_return(status: 500)

      expect { described_class.build.chat(parameters: chat_parameters) }
        .to output_nothing.to_stdout
        .and raise_error(StandardError)
    end

    it "raises an OpenAIClient::ClientError when a client error occurs" do
      stub_request(:post, /openai\.com/).to_return(status: 400)

      expect { described_class.build.chat(parameters: chat_parameters) }
        .to raise_error(OpenAIClient::ClientError)
    end

    it "raises an OpenAIClient::ServerError when a server error occurs" do
      stub_request(:post, /openai\.com/).to_return(status: 500)

      expect { described_class.build.chat(parameters: chat_parameters) }
        .to raise_error(OpenAIClient::ServerError)
    end

    it "raises an OpenAIClient::RequestError when a non-specific error occurs" do
      stub_request(:post, /openai\.com/).to_timeout

      expect { described_class.build.chat(parameters: chat_parameters) }
        .to raise_error(OpenAIClient::RequestError)
    end
  end
end
