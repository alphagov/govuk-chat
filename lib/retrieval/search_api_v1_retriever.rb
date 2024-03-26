module Retrieval
  class SearchApiV1Retriever
    def self.call(...) = new(...).call

    def initialize(query:)
      @query = query
      @search_api = GdsApi::Search.new("https://www.gov.uk/api")
    end

    def call
      search_api.search(
        q: query, fields: %w[description title indexable_content link],
      )["results"].map(&method(:format_result))
    end

  private

    attr_reader :query, :search_api

    def format_result(result)
      <<~OUTPUT
        Title: #{result['title']}

        Description: #{result['description']}

        Uri: https://www.gov.uk#{result['link']}

        Content: #{result['indexable_content'].truncate_words(500, ommision: '')}
      OUTPUT
    end
  end
end
