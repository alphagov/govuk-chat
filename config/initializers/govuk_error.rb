GovukError.configure do |config|
  config.excluded_exceptions += [
    "Search::ChunkedContentRepository::NotFound",
    "ThrottledRequest",
  ]
end
