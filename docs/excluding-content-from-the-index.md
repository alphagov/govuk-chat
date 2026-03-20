# Excluding content from the index

Sometimes we might want to exclude content from being indexed, for example if the content contains PII.

To exclude a content item by its `content_id`, you need to add the content ID to the `indexing_excluded_content_ids.yml` file in the `govuk_chat_private` repo.

## Manually deleting content from the index

If you've added a new content ID to the configuration data in the `govuk_chat_private` repo, you can delete all of the chunks that reference that content ID by running the following rake task:

```
rake search:delete_all_excluded_chunks
```
