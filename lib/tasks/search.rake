namespace :search do
  desc "Create an index for chunked_content"
  task create_chunked_content_index: :environment do
    puts "Creating chunked content index"
    Search::ChunkedContentRepository.new.create_index
    puts "Index created"
  rescue OpenSearch::Transport::Transport::Errors::BadRequest => e
    # Using a regex as the message is a JSON object as a string
    raise e unless e.message.match?(/resource_already_exists/)

    puts "Index already exists run rake search:recreate_chunked_content_index to recreate it"
  end

  desc "Delete an existing chunked content opensearch index and create a new one"
  task recreate_chunked_content_index: :environment do
    if Rails.env.production?
      puts "This task has been disabled for production environments"
      exit 1
    end

    puts "Recreating chunked content index"
    Search::ChunkedContentRepository.new.create_index!
    puts "Index created"
  end

  desc "Set schema_name for existing documents"
  task set_schema_name: :environment do
    mappings = {
      "answer" => "answer",
      "business_finance_support_scheme" => "specialist_document",
      "detailed_guide" => "detailed_guide",
      "export_health_certificate" => "specialist_document",
      "form" => "publication",
      "guidance" => "publication",
      "guide" => "guide",
      "help_page" => "help_page",
      "international_development_fund" => "specialist_document",
      "licence_transaction" => "specialist_document",
      "manual" => "manual",
      "manual_section" => "manual_section",
      "notice" => "publication",
      "promotional" => "publication",
      "regulation" => "publication",
      "service_manual_guide" => "service_manual_guide",
      "simple_smart_answer" => "simple_smart_answer",
      "statutory_guidance" => "publication",
      "step_by_step_nav" => "step_by_step_nav",
      "transaction" => "transaction",
      "travel_advice" => "travel_advice",
      "worldwide_organisation" => "worldwide_organisation",
    }

    repo = Search::ChunkedContentRepository.new
    client = repo.client

    mappings.each do |document_type, schema_name|
      result = client.update_by_query(
        index: repo.index,
        body: {
          query: {
            bool: {
              must: [
                { term: { document_type: } },
              ],
              must_not: [
                { exists: { field: "schema_name" } },
              ],
            },
          },
          script: {
            source: "ctx._source.schema_name = params.schema_name",
            params: {
              schema_name:,
            },
          },
        },
      )
      puts "#{document_type}: updated #{result['updated']} of #{result['total']} documents"
    end
  end

  desc "Update the chunked context index mappings"
  task update_chunked_content_mappings: :environment do
    puts "Adding missing content mappings"

    mappings = Search::ChunkedContentRepository.new.update_missing_mappings

    if mappings.present?
      puts "Mapping(s) added for: #{mappings.join(', ')}"
    else
      puts "No mappings were added"
    end
  end

  desc "Populate the Chunked Content OpenSearchIndex with data from seed files"
  task populate_chunked_content_index_from_seeds: %i[environment create_chunked_content_index] do
    if Rails.env.production?
      puts "This task has been disabled for production environments"
      exit 1
    end

    content = Dir["db/chunked_content_seeds/*.yml"].flat_map { |file| YAML.load_file(file) }

    chunks = content.flat_map do |item|
      faux_content_item = item.except("chunks").merge(
        "content_id" => SecureRandom.uuid,
        "locale" => "en",
      )

      item["chunks"].map.with_index do |chunk, index|
        Chunking::ContentItemChunk.new(content_item: faux_content_item,
                                       html_content: chunk["html_content"],
                                       heading_hierarchy: chunk["heading_hierarchy"],
                                       chunk_index: index,
                                       exact_path: chunk["exact_path"])
      end
    end

    embeddings = Search::TextToEmbedding.call(chunks.map(&:plain_content))
    repository = Search::ChunkedContentRepository.new
    indexed = 0

    base_paths = chunks.map(&:base_path).uniq
    deleted = base_paths.inject(0) do |memo, base_path|
      memo + repository.delete_by_base_path(base_path)
    end

    puts "#{deleted} conflicting chunks deleted"

    chunks.each.with_index do |chunk, index|
      document = chunk.to_opensearch_hash.merge(
        titan_embedding: embeddings[index],
      )
      repository.index_document(chunk.id, document)
      indexed += 1
    end

    puts "#{indexed} chunks indexed"
  end
end
