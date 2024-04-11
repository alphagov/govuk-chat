class Chunking::HtmlHierarchicalChunker
  HtmlChunk = Data.define(:headers, :html_content) do
    def fragment
      headers.map(&:fragment).compact.last
    end
  end

  HtmlChunk::Header = Data.define(:element, :text_content, :fragment)
end
