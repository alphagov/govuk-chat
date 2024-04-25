# Populating OpenSearch

We use [OpenSearch](https://opensearch.org/) to store an index of GOV.UK content which has been chunked. In production environments we populate this data by [consuming the Publishing API message queue](./message-queue-consumption.md). This document describes how the search index can be populated outside these environments.

## In development

This repo contains a number of seed files that can be used to populate a small search index of chunked content. These are stored in [db/chunked_content_seeds/](../db/chunked_content_seeds/) with a [README](../db/chunked_content_seeds/README.md) to explain how they are generated.

These can be populated by running:

```
bundle exec rake search:populate_chunked_content_index_from_seeds
```

If you need to populate a development instance with actual GOV.UK content, for a more representative search experience there are [steps documented](./message-queue-consumption.md#consuming-queues-in-a-development-environment).

## In Heroku

In our Heroku pipeline we share a single instance of OpenSearch across all the GOV.UK chat application instances. This instance is hosted on AWS in the govuk-test environment and is tagged with kevindew, as the person who created it. The credentials for accessing OpenSearch are available in AWS Secret Manager, on govuk-test, under: `kevindew/govuk-chat/opensearch-for-heroku-credentials`.

The process to populate this OpenSearch instance involves using a local machine to write to the OpenSearch instance. This can be done using the documented approach to [consuming queues in a development environment](./message-queue-consumption.md#consuming-queues-in-a-development-environment) to publish a subset of GOV.UK content. To do this we need the queue consumer to be configured to use the AWS hosted OpenSearch instance:

```
govuk-docker run -e OPENSEARCH_URL=<AWS OpenSearch URL with credentials> govuk-chat-queue-consumer bin/dev queue_consumer
```

In future we plan to have this OpenSearch instance be automatically updated from a GOV.UK production snapshot so it no longer needs manual populating.
