# Message Queue consumption

GOV.UK Chat stores a search index of GOV.UK content which is populated by consuming the [Publishing API `published_documents` message queue](https://github.com/alphagov/publishing-api/blob/main/docs/rabbitmq.md). This search index provides access to relevant GOV.UK Content in order to answer users' questions.

## How it works

Whenever the GOV.UK Publishing API pushes a content change to the Content Store it emits an event to a message broker, the `published_documents` exchange, with a JSON representation of the Content Item. This exchange broadcasts these messages to a queue which this application listens to.

When receiving a message from this queue, this application will create a distributed lock based on the `base_path` of the Content Item received (to ensure two pieces of content at the same GOV.UK location are not being indexed concurrently as they will try delete each other's data) and it will check whether there is already an indexed document that is newer and uses the same `base_path` (to prevent old messages invalidating current data).

Once it is established that the message is not out of date, this application will then synchronise the data from the Content Item with the search index. Synchronising the content involves establishing whether the Content Item is in a supported schema, is in English and in a supported state (for example not withdrawn) - if these pre-conditions are not met any indexed content for the `base_path` is deleted. When these conditions are met the search index is updated.

Updating the search index involves decomposing the HTML from the Content Item into a number of smaller subsets of HTML that are organised around the HTML header structure (H2 - H6 elements). Once a collection of chunks has been established for a Content Item these will be compared with what is already in the search index to avoid updating items that have not changed. Adding and updating items involves creating an [embedding](https://platform.openai.com/docs/guides/embeddings) representation of the indexable content, this embedding will be used as part of searching for content using a [k-nearest neighbour](https://en.wikipedia.org/wiki/K-nearest_neighbors_algorithm) semantic search.

Should an exception occur during the processing of a message then the behaviour of the handling will depend on whether the exception is anticipated or not. For anticipated exceptions the message is marked for retry and pushed back to the queue to be reattempted. For an exception type that was not anticipated the message is discarded and not retried - this is because it is expected that this represents a scenario where a developer needs to fix the code and that retrying the message would not be beneficial due to the extended time frame for a fix.

## Starting the queue consumer

The queue consumer is started by a rake task:

```
rake message_queue:published_documents_consumer
```

You can run it in GOV.UK Docker for development. You'll have to create the queue first:

```
govuk-docker-run bundle exec rake message_queue:create_published_documents_queue
```

and then start it with:

```
govuk-docker-up queue-consumer
```

## Bulk indexing all GOV.UK content

You will want to follow these steps in one of two situations:

1. you've setup the queue consumer and Opensearch index and want to populate the index for the first time
2. you're reindexing and need to bulk requeue documents to populate the new fields

**Note: This will take a significant amount of time as it will requeue each live document on GOV.UK (as of 2/7/2024 close to 1 million) to the message queue.**

Prior to running the rake task to queue the documents you should ensure that you have the necessary monitoring setup so that you have good visibiity
of the process. You should use:

**Note: These links are for production. If you're bulk indexing another environment you will need to update the environemnt in the urls accordingly**

- [Sidekiq](https://grafana.eks.production.govuk.digital/d/sidekiq-queues/sidekiq3a-queue-length-max-delay?orgId=1&var-namespace=apps&var-app=publishing-api-worker) to monitor the queue length
on Publishing API
- [Sentry](https://govuk.sentry.io/issues/?environment=production&project=4507072589070336&statsPeriod=14d) to check any errors that might occur during the process
- [RabbitMQ web control panel](https://docs.publishing.service.gov.uk/manual/amazonmq.html) to view the queue length. Once the RabbitMQ HTTPS port has been forwarded to your local machine you can visit [https://localhost:4430/#/queues/publishing/govuk_chat_published_documents](https://localhost:4430/#/queues/publishing/govuk_chat_published_documents) to view the dashboard for the `govuk_chat_published_documents` queue
- [Argo CD](https://argo.eks.production.govuk.digital/applications/govuk-chat?orphaned=false&resource=) or [Logit](https://dashboard.logit.io/a/1c6b2316-16e2-4ca5-a3df-ff18631b0e74) for application logs.

Once you're confident you have sufficient monitoring in place you can run the following [rake task](https://github.com/alphagov/publishing-api/blob/main/lib/tasks/queue.rake#L41-L52) from Publishing API.

```bash
rake queue:requeue_all_the_things["bulk.govuk_chat_sync"]
```

You can check the count of documents in the index to confirm that documents are being indexed with the following code from [Rails console](https://docs.publishing.service.gov.uk/kubernetes/cheatsheet.html#open-a-rails-console) in govuk-chat:

```bash
r = Search::ChunkedContentRepository.new
r.client.count(index: r.index)
```

## Consuming queues in a development environment

It can take a long time to index all GOV.UK content, so just indexing the subset of content from Mainstream Publisher is recommended.

The process to do this with GOV.UK Docker is:

1. [Replicate the Publishing API Data](https://github.com/alphagov/govuk-docker/blob/main/docs/how-tos.md#how-to-replicate-data-locally) to GOV.UK Docker
2. Start a process to run the Publishing API Sidekiq worker in GOV.UK Docker with `govuk-docker up publishing-api-worker`
3. Create a new terminal window and start the queue consumer process with `govuk-docker up govuk-chat-queue-consumer`
4. Create a new terminal window and navigate to the Publishing API directory, `cd ~/govuk/publishing-api`
5. Open a Rails console for the Publishing API `govuk-docker-run bundle exec rails console`
6. To queue just content from Mainstream Publisher: `RequeueContentByScope.new(Edition.live.where(publishing_app: "publisher"), action: "bulk.govuk_chat_sync").call`

You can check on the progress of the queue consumption by following the Rails log file for GOV.UK Chat `tail -f logs/development.log`.

## Adding a new schema for indexing

For a schema to be supported by GOV.UK Chat it needs to be registered with a corresponding Parser class. These are registered in [`Chunking::ContentItemToChunks::PARSERS_FOR_SCHEMAS`](../lib/chunking/content_item_to_chunks.rb). The Parser class has the responsibility of converting the Content Item into a number of chunks.

To add a new schema you will have to establish what HTML from the Content Item is appropriate to be indexed into search for GOV.UK Chat. If there isn't any, then it probably shouldn't be added.

Lots of GOV.UK Content have only one field that needs to be indexed `details->body`.

The publishing API has 2 different formats for the body - you need to check [the publisher content schema](https://docs.publishing.service.gov.uk/content-schemas/help_page.html#publisher-content-schema)

If `body` is a string we have a parser class already for this field ([`BodyContentParser`](../lib/chunking/content_item_parsing/body_content_parser.rb)) so to add an additional schema that only uses this field then we just need to add the schema name to the list of schemas already supported for this parser.

If `body`  is an array with markdown and html versions - use [`BodyContentArrayParser`](../lib/chunking/content_item_parsing/body_content_array_parser.rb)

If you have a schema that has HTML in different fields you'll need to create a new parser class in the [`Chunking::ContentItemParsing`](../lib/chunking/content_item_parsing/) namespace, which inherits from [`Chunking::ContentItemParsing::BaseParser`](../lib/chunking/content_item_parsing/base_parser.rb). This parser will need to implement a `.call` method and the class will need to concatenate the HTML together before calling the `build_chunks` method to convert that HTML into chunks. An example of this can be seen in [`Chunking::ContentItemParsing::TransactionParser`](../lib/chunking/content_item_parsing/transaction_parser.rb).

If you have a more complex schema that needs to have granular control of the chunks that are created (for example content that has parts which have different URLs) then you'll have to write more code. An example of this type of complex schema handling is [`Chunking::ContentItemParsing::GuideParser`](../lib/chunking/content_item_parsing/guide_parser.rb).

## Known issues

- The message queue consumer process is single process and single threaded so a single process can only consumer one message at a time. Run multiple processes for concurrency.
- There isn't any guarantee that messages are received in a particular order from the Publishing API message queue, so message metadata has to be relied on for integrity.
- There isn't a mechanism to support only a subset of the document types of a schema being indexed, should this be needed it should be trivial to add.
- It is possible that a race condition could occur if a scenario occurs where two Content Items are indexed simultaneously and both have the same `content_id` and `locale` values but different values for `base_path`. Should this prove an issue in practice we will need to use a [non-deterministic id for search indexing](https://github.com/alphagov/govuk-chat/commit/01358a0749ca6f67e371a17602d0cc10c2ab3d34).
-  The retry mechanism for messages is simplistic, items are just re-added to the queue and retried as soon as they are reached again in the queue. This could lead to frequently experiencing the same error.
- We aspire to have only exceptions reported to Sentry that represent something a developer needs to fix and not any transient errors. However until we establish what are common transient errors we are reporting all errors to Sentry.
