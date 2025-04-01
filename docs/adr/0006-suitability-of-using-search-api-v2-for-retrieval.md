# 6. Suitability of using Search API V2 for retrieval

Date: 2025-03-24

## Context
The Search API V2 [1] app uses Google Vertex AI Search [2] (VAIS) to index and retrieve GOV.UK content, whereas GOV.UK Chat uses an OpenSearch cluster. Both applications operate on the same content (i.e. published documents) and provide results based on a search query.

There was a question as to whether GOV.UK Chat could replace its OpenSearch implementation with VAIS via Search API v2, and lean on this managed service for document retrieval instead of maintaining our own separate system. This was due to VAIS being marketed as a tool well suited for Retrieval-Augmented Generation (RAG) systems.

Currently the indexing process for GOV.UK Chat is as follows:

1. A content item is read off a RabbitMQ queue after it's published
2. The item is chunked according to custom logic (see the implementation in `lib/chunking`)
3. An embedding is created using an OpenAI embedding model for each chunk (see `Search::TextToEmbedding`)
4. Each chunk is indexed in OpenSearch

And for retrieval:

1. The query (i.e. the user's question) is converted to an embedding using the same OpenAI embedding model
2. The OpenSearch index is searched using that embedding (see `Search::ChunkedContentRepository`)
3. We take each search result and interpolate the GOV.UK content of each one into the LLM prompt

There's a lot of custom logic that we've needed to write to do the chunking - and we've not covered all document types yet - which needs maintaining. We also need to maintain multiple OpenSearch clusters which takes developer resource.

## Decision
After some experimentation, it was decided not to use VAIS at this time for GOV.UK Chat.

### Rationale
- VAIS has its own concept of chunking which it can do automatically. However this is an opaque system and it has few configuration options. The way we chunk content on GOV.UK Chat results in semantic chunks for a document, which vary in size depending on the content in that part of the page - this allows us to link to specific parts of a page on GOV.UK when we return sources to the user. VAIS chunking is instead only configurable at a size level so we can have either have only very small chunks or very large ones.
- VAIS does offer a service to "bring your own chunks", i.e. you chunk your content and then import those chunks instead of letting VAIS do it. A downside to this is that at the time of writing you can't import these chunks via an API like full document ingesting. You need to write the chunks to Google Cloud Storage as a JSONL file and then import them via an API call. This isn't impossible to do by any means, but it's a lot more work to store, process and clean up the data.
- With the "bring your own chunks" approach, you can't currently assign any metadata to the chunks. So we'd lose the ability to link to specific parts of a page on GOV.UK again.
The Search API V2 datastore is not chunked and were it be a chunked one this would incur a performance penalty for Search API V2 operations [3]. Therefore we believe that in order for Search API V2 to support providing chunked GOV.UK content this would need a secondary data store, which would incur an additional decision point whenever interactions with datastore are considered as to whether they should apply to all data stores.
- The Search API v2 codebase would need to be extended to handle this specific use-case for GOV.UK Chat. This means setting up a new infrastructure, new configuration and additional logic to index the content. With GOV.UK Chat being the initial consumer, and implementer of the changes, there would be confusion over product ownership and direction.
- The content that is indexed for Search API V2 is not configured to be retrievable and, were it available, is not suitable to be pulled out for RAG as it is something of a dump of all possible content with repetition in various cases [4]. Thus a new indexing approach would be needed.

Essentially, we decided that despite Search API V2 and GOV.UK Chat both creating search indexes and the underlying technology of Search API V2 - VAIS - being suited for RAG applications, ultimately it would be a significant change to Search API V2 in order to provide the search index for GOV.UK Chat. Therefore we believe that this is not a worthy route to invest time as we don't know enough about future product changes and scopes to justify that as a sound decision that will be beneficial to both the teams looking after GOV.UK Chat and Search API V2.

We do consider that should we enter a phase of work exploring the iteration of the retrieval logic of GOV.UK Chat then VAIS remains a platform that should be evaluated as a potential technology choice.

## Status
Accepted

## Consequences
- GOV.UK Chat will continue to have the responsibility of indexing GOV.UK content and will need to continue using an embedded model
- Search API V2 is not currently planned to provide an interface to access chunked GOV.UK Content and should other government teams need this information we would still need to work out the appropriate service for it
- GOV.UK Chat will not be tied to the roadmap of Search API V2 and could choose to explore other search technologies if and when retrieval is optimised
- GOV.UK Chat will continue to have the financial overhead of OpenSearch, which at low usage is substantially more expensive than VAIS
- GOV.UK Chat may need to consider offering an API for search results, or splitting search into a separate project should there be an established need for accessing chunked GOV.UK content by other teams or projects.


[1]: https://github.com/alphagov/search-api-v2
[2]: https://cloud.google.com/enterprise-search?hl=en
[3]: https://cloud.google.com/generative-ai-app-builder/docs/parse-chunk-documents#limitations
[4]: https://github.com/alphagov/search-api-v2/blob/1c1d9f05e2def51b035b19caa92cbcde55346e1c/app/models/concerns/publishing_api/content.rb#L9-L52
