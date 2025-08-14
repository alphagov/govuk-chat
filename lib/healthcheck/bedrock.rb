module Healthcheck
  class Bedrock
    attr_reader :message

    def name
      :bedrock
    end

    def status
      client = Aws::BedrockRuntime::Client.new
      client.invoke_model(
        model_id: BedrockModels::TITAN_EMBED_V2,
        body: { inputText: "test" }.to_json,
      )
      GovukHealthcheck::OK
    rescue StandardError => e
      @message = e.message
      GovukHealthcheck::CRITICAL
    end
  end
end
