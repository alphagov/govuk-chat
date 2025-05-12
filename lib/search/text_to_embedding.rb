module Search
  class TextToEmbedding
    def self.call(single_or_collection_of_text, llm_provider:)
      case llm_provider.to_sym
      when :openai
        Search::TextToEmbedding::OpenAI.call(single_or_collection_of_text)
      when :titan
        Search::TextToEmbedding::Titan.call(single_or_collection_of_text)
      else
        raise "Unknown provider: #{llm_provider}"
      end
    end
  end
end
