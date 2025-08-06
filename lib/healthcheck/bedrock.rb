module Healthcheck
  class Bedrock
    attr_reader :message

    def name
      :bedrock
    end

    def status
      if unsupported_model_ids.any?
        @message = "Bedrock model(s) not available: #{unsupported_model_ids.sort.join(', ')}"
        GovukHealthcheck::CRITICAL
      else
        GovukHealthcheck::OK
      end
    rescue StandardError => e
      @message = "Failure to communicate to Bedrock: #{e.message}"
      GovukHealthcheck::CRITICAL
    end

  private

    def unsupported_model_ids
      @unsupported_model_ids ||= BedrockModels.expected_foundation_models - available_model_names
    end

    def available_model_names
      @available_model_names ||= Aws::Bedrock::Client.new.list_foundation_models.model_summaries.map(&:model_id)
    end
  end
end
