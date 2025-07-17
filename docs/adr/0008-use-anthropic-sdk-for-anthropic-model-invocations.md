# 8. Use Anthropic SDK for Anthropic models

**Date:** 2025-07-14

## Context

We are using Claude models for answer composition in GOV.UK Chat. Initially, we chose to integrate with Claude via AWS Bedrock’s `converse` API using the `aws-sdk-bedrockruntime` gem. At the time, this offered a unified interface for accessing multiple model providers and avoided the lower-level concerns of working with `invokeModel` directly—such as having to manually parse payloads.

However, over time, we ran into several limitations with this approach:

- We often had to consult both AWS and Anthropic documentation to understand the API structure and behavior, since the Converse API is abstracted to work with many models and does not fully mirror Anthropic's interface.
- Certain Claude features, like `disable_parallel_tool_use`, were either unsupported or undocumented by the Bedrock SDK.
- Prompt caching was difficult to manage. While Bedrock technically supports `cache_control`, it only supports caching the entire system prompt. Splitting static and dynamic sections into separate system messages did not work reliably—the cache would only match if the same set of chunks appeared in the exact order, making partial caching effectively unusable.

Since our original implementation, Anthropic released an official Ruby SDK that includes native support for calling Claude models hosted on AWS via `Anthropic::BedrockClient`. This presents a cleaner and more predictable implementation and is aligned with Anthropic’s own API documentation.

## Decision

We have ported our Claude integration from the AWS SDK for Bedrock to the [official Anthropic SDK for Ruby](https://github.com/anthropics/anthropic-sdk-ruby), specifically using its `Anthropic::BedrockClient` interface. This allows us to continue using Claude models hosted on AWS Bedrock, but through Anthropics SDK which is designed to expose the full range of Claude's features.

## Status

**accepted**

## Consequences

- All Claude interactions now use the Anthropic SDK rather than the AWS Bedrock Converse API
- We gain reliable, partial system prompt caching using `cache_control`
- Claude features not available via the Converse API—such as citations are now accessible
- Testing integrations is easier, particularly across platforms (e.g., Bedrock and GCP Vertex)
- If we need to access features that are only exposed via Converse (and not supported by the Anthropic SDK), we may need to revert back to using the Converse API
- We continue to use the AWS Bedrock SDK directly for generating embeddings
