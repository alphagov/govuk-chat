module Search
  class TextToEmbedding
    def self.call(single_or_collection_of_text)
      Search::TextToEmbedding::Titan.call(single_or_collection_of_text)
    end
  end
end
