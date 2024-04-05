namespace :search do
  desc "Create an index for chunked_content"
  task create_chunked_content_index: :environment do
    Search::ChunkedContentRepository.new.create_index
  end

  desc "Delete an existing chunked content opensearch index and create a new one"
  task recreate_chunked_content_index: :environment do
    if Rails.env.production?
      puts "This task has been disabled for production environments"
      exit 1
    end

    Search::ChunkedContentRepository.new.create_index!
  end
end
