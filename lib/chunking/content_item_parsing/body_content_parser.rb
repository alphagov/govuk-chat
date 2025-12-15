module Chunking::ContentItemParsing
  class BodyContentParser < BaseParser
    def call
      content = details_field!("body")

      build_chunks(content)
    end
  end
end
