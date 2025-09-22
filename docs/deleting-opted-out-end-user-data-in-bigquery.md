# Deleting opted-out end user data in BigQuery

When using the app, users have the ability to opt out of having us use their data for analysis. We expect this to be a relatively low number of users so for now the process is manual. If the numbers of users increase, we will revisit this and automate it.

When the App team contact us to let us know a user has opted out you should do the following.

## Adding the users end-user-id to the private repo

Add the users `end-user-id` to the [opted out end user configuration](https://github.com/alphagov/govuk_chat_private/blob/main/config/opted_out_end_user_ids.yml) in the private repository.

This will ensure that data on their conversations will be excluded from our BigQuery exports.

## Deleting existing end user data

After adding the `end-user-id` to the private repo you should ensure you delete any existing data for that user. You can do this by calling the [bigquery:delete_opted_out_end_user_data](https://github.com/alphagov/govuk-chat/blob/74e8f69b137f3eb658783574593995a3ae0a1ffe/lib/tasks/bigquery.rake) rake task. This rake task requires an `end-user-id` to be passed in as an argument.

This rake task should be run on production. An example of this rake task being called is:

```
rake bigquery:delete_opted_out_end_user_data["real-end-users-id"]
```
