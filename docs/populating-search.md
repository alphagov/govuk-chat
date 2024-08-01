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

In our Heroku pipeline we share a single instance of OpenSearch across all the GOV.UK chat application instances. This instance is hosted on AWS in the govuk-test environment and is tagged with chat-engine-test. The credentials for accessing OpenSearch are available in AWS Secret Manager, on govuk-integration, under: `govuk/govuk-chat/opensearch-test`.

This instance has it's data populated nightly with a copy of productions search index. So it should not need to be updated.

To work with this search index locally you should grab the read-only credentials from the secret (the ones suffixed with `-ro`) and set env vars of `OPENSEARCH_URL=`, `OPENSEARCH_USERNAME=` and `OPENSEARCH_PASSWORD=`.

You can use the other credentials, the master user, if we ever need to write to this index.
