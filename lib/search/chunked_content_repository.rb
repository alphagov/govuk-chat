module Search
  class ChunkedContentRepository
    attr_reader :index, :client

    def initialize
      @index = Rails.configuration.opensearch.chunked_content_index!
      @client = OpenSearch::Client.new(url: Rails.configuration.opensearch.url)
    end
  end
end
