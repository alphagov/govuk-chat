# Manual Build of Chat Opensearch Cluster

## In Test Account
These tasks are to be carried out manually in the AWS Console:
- Create certificate in Certificate Manager for `chat-opensearch-test.integration.govuk-internal.digital`
- Create password for `chat-masteruser`
- Create Opensearch cluster `chat-engine-test` with the following configuration:
  - Dev/Test template
  - Domain without standby
  - Single AZ
  - Engine version to match Production
  - Data node and master node instance family to match Production
  - Storage to match Production
  - Minimum required quantity of nodes
  - Custom endpoint `chat-opensearch-test.integration.govuk-internal.digital` with certificate to match
  - Public access
  - Enable fine-grained access control
  - Create master user `chat-masteruser`
  - Add standard tags
- Create IAM Policy `govuk-test-chat-opensearch-snapshot-bucket-policy` with permission for Opensearch to access the Production Snapshot S3 Bucket
```
{
    "Statement": [
        {
            "Action": "s3:ListBucket",
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::govuk-production-chat-opensearch-snapshots"
            ]
        },
        {
            "Action": [
                "s3:PutObject",
                "s3:GetObject"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::govuk-production-chat-opensearch-snapshots/*"
            ]
        }
    ],
    "Version": "2012-10-17"
}
```
- Create IAM Role `govuk-test-chat-opensearch-snapshot-role` with the following trust relationship and attach IAM Policy `govuk-test-chat-opensearch-snapshot-bucket-policy`
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Principal": {
                "Service": "es.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```
- Log into Opensearch Dashboard and create user `chat-heroku-user` with read only permissions by attaching it to the `readall_and_monitor` role
- Register the Production S3 Bucket as a repository following instructions found [here]

> [!NOTE]
> If recreating this cluster as a new resource, the `test_opensearch_url` variable will need to be updated in `govuk-infrastructure/terraform/deployments/tfc-configuration/variables-integration.yaml` with the new public endpoint

[here]: https://github.com/alphagov/govuk-infrastructure/blob/main/terraform/deployments/opensearch/README.md

---

## In Integration Account
This task is to be carried out manually in the AWS Console:
- Add the credentials for `chat-masteruser` and `chat-heroku-user` in Secrets Manager secret `govuk/govuk-chat/opensearch-test`, along with the new url for the Opensearch Cluster Public Endpoint
