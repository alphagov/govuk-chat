RSpec.describe OpenAIClient do # rubocop:disable RSpec/SpecFilePathFormat
  describe ".build" do
    let(:chat_parameters) do
      {
        model: "gpt-3.5-turbo",
        messages: [{ role: "user", content: "Hello!" }],
      }
    end

    let(:embeddings_parameters) do
      {
        model: "text-embedding-small",
        input: "",
      }
    end

    it "returns an OpenAI::Client instance" do
      expect(described_class.build).to be_an_instance_of(OpenAI::Client)
    end

    it "sets the request timeout to the configuration value" do
      allow(Rails.configuration).to receive(:openai_request_timeout).and_return(10)
      expect(described_class.build.request_timeout).to eq(10)
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

    it "raises an OpenAIClient::ContextLengthExceededError when user input exceeds allowed tokens" do
      stub_openai_chat_completion_error(status: 400,
                                        type: "invalid_request_error",
                                        code: "context_length_exceeded")

      expect { described_class.build.chat(parameters: chat_parameters) }
        .to raise_error(OpenAIClient::ContextLengthExceededError)
    end

    it "sets OpenAI chat completion rate limit Prometheus gauges" do
      allow(Metrics).to receive(:gauge)
      stub_request(:post, /openai\.com/)
        .to_return_json(
          headers: {
            "x-ratelimit-remaining-tokens" => 90_000_000,
            "x-ratelimit-limit-tokens" => 150_000_000,
            "x-ratelimit-remaining-requests" => 21_000,
            "x-ratelimit-limit-requests" => 30_000,
          },
        )

      described_class.build.chat(parameters: chat_parameters)

      expect(Metrics).to have_received(:gauge).with("openai_remaining_tokens", 90_000_000, { endpoint: "/v1/chat/completions", model: chat_parameters[:model] })
      expect(Metrics).to have_received(:gauge).with("openai_tokens_used_percentage", 40.0, { endpoint: "/v1/chat/completions", model: chat_parameters[:model] })
      expect(Metrics).to have_received(:gauge).with("openai_remaining_requests", 21_000, { endpoint: "/v1/chat/completions", model: chat_parameters[:model] })
      expect(Metrics).to have_received(:gauge).with("openai_requests_used_percentage", 30.0, { endpoint: "/v1/chat/completions", model: chat_parameters[:model] })
    end

    it "sets OpenAI embeddings rate limit Prometheus gauges" do
      allow(Metrics).to receive(:gauge)
      stub_request(:post, /openai\.com/)
        .to_return_json(
          headers: {
            "x-ratelimit-remaining-tokens" => 90_000_000,
            "x-ratelimit-limit-tokens" => 150_000_000,
            "x-ratelimit-remaining-requests" => 21_000,
            "x-ratelimit-limit-requests" => 30_000,
          },
        )

      described_class.build.embeddings(parameters: embeddings_parameters)

      expect(Metrics).to have_received(:gauge).with("openai_remaining_tokens", 90_000_000, { endpoint: "/v1/embeddings", model: embeddings_parameters[:model] })
      expect(Metrics).to have_received(:gauge).with("openai_tokens_used_percentage", 40.0, { endpoint: "/v1/embeddings", model: embeddings_parameters[:model] })
      expect(Metrics).to have_received(:gauge).with("openai_remaining_requests", 21_000, { endpoint: "/v1/embeddings", model: embeddings_parameters[:model] })
      expect(Metrics).to have_received(:gauge).with("openai_requests_used_percentage", 30.0, { endpoint: "/v1/embeddings", model: embeddings_parameters[:model] })
    end

    it "doesn't set gauges if remaining tokens or requests isn't returned in the header" do
      allow(Metrics).to receive(:gauge)
      stub_request(:post, /openai\.com/)

      described_class.build.chat(parameters: chat_parameters)

      expect(Metrics).not_to have_received(:gauge)
    end
  end
end
