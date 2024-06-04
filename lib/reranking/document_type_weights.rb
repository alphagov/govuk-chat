class Reranking::DocumentTypeWeights
  def self.call(document_type)
    Rails.configuration.chunked_content_reranking[document_type] || 1.0
  end
end
