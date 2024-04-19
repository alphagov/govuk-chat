module Search
  class ResultsForQuestion
    attr_reader :question_message

    def self.call(question_message)
      embedding = Search::TextToEmbedding.call(question_message)
      ChunkedContentRepository.new.search_by_embedding(embedding)
    end
  end
end
