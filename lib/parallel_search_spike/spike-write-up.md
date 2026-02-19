# Parallel retrieval

## Recommendation:

1. Start with a "hybrid" retrieval shape for multi‑phrase retrieval:
   - Parallelise Titan embeddings with a small, bounded concurrency.
   - Then do one OpenSearch `_msearch` across all embeddings.
   - Rerank/filter per phrase using existing logic.

2. Do not parallelise the full pipeline per phrase in production (for now):
   - It can be fastest, but it increases total outbound requests (especially OpenSearch fan-out) and makes it easier to hit throttling/timeouts and socket pressure under Sidekiq/pod scaling.

3. Do not adopt bespoke async HTTP + manual SigV4 for Bedrock for the production path:
   - It avoids Ruby thread pools (Typhoeus Hydra uses libcurl multi, not Ruby threads), but productionising it means owning SigV4 signing and credential refresh under IRSA, plus extra work to keep retries, error handling, and monitoring consistent with the rest of the app.

---

## 1) What we're solving

Input:

- LLM produces a list of phrases: `["phrase 1", "phrase 2", ...]`

Output (design requirements for production - not yet validated end-to-end by the spike harness):

- Per‑phrase result sets that:
  - isolate errors per phrase (one phrase failing shouldn't fail the whole run)
  - do not merge/dedupe across phrases

---

## 2) No API route for batch embeddings

Titan's `invoke_model` accepts a single `inputText` per request - there is no server-side batching API for embeddings at query time. (`Search::TextToEmbedding::Titan` loops `text_collection.map` and issues one `invoke_model` call per item.) This means client-side parallelism is the only way to reduce embedding latency for multiple phrases.

---

## 3) Strategies tested

Threaded spike results (5 phrases, 10 runs each):

| Strategy | Avg | Speedup |
|---|---|---|
| sequential | 0.959s | x1.00 |
| `bounded_pool` | 0.254s | x3.78 |
| `parallel_per_phrase` | 0.298s | x3.22 |
| `hybrid` | 0.354s | x2.71 |
| `msearch_only` | 0.693s | x1.38 |

Async HTTP signed Bedrock embedding spike (5 phrases, 5 runs):

- sequential avg 0.657s
- async avg 0.258s (x2.54)

Interpretation:

- Embedding latency dominates. `msearch_only` shows batching OpenSearch alone barely helps; the speedup comes from parallelising the Bedrock embedding calls.
- Full pipeline parallelism is fastest (`bounded_pool`, `parallel_per_phrase`) because it pipelines embedding and OpenSearch I/O across phrases - while phrase A is searching OpenSearch, phrase B is still embedding.
- Hybrid is consistently slower than full pipeline because it introduces a phase barrier: all embeddings must complete before the single `_msearch` fires, eliminating that cross-phrase overlap.
- Hybrid is still a strong improvement (x2.71 over sequential) and trades some latency for operational simplicity (one OpenSearch request, no parallel OpenSearch calls).

---

## 4) Ruby/Rails concurrency precedent

### concurrent-ruby in Rails

Rails depends on `concurrent-ruby` (via `activesupport`). It's already in our `Gemfile.lock` and available without an explicit dependency.

The spike uses `Concurrent::FixedThreadPool`, which pre-allocates a fixed number of threads. `Concurrent::ThreadPoolExecutor` is also available and supports `min_threads` / `max_threads` - it can scale down when idle. `ThreadPoolExecutor` may be more appropriate for production since it avoids holding idle threads when no parallel work is happening.

### Rails executor

Any concurrent work that touches Rails autoloading or ActiveRecord must be wrapped in `Rails.application.executor.wrap`. The spike demonstrates this pattern in `build_worker`.

### Open question: pool-per-job vs pool-per-process

Two approaches for production:

- Pool per job: each `ComposeAnswerJob` creates a small thread pool, uses it, shuts it down. Simpler lifecycle, but means threads are created/destroyed frequently under load.
- Shared pool per process: a single pool lives for the process lifetime, shared across Sidekiq workers. Avoids thread churn but needs careful shutdown handling on deploy (Sidekiq process lifecycle) and adds shared-state complexity.

Starting with pool-per-job and small parallelism (2 threads) is more conservative, so might be a good initial approach. But note that with `SIDEKIQ_CONCURRENCY=25`, "pool per job" can also mean a lot of extra Ruby threads per process, so we should keep the pool small and watch memory/CPU.

---

## 5) Recommended design (hybrid: bounded embeddings -> single `_msearch`)

Pipeline:

1. Bounded parallel Titan embeddings (Bedrock)

- For each phrase: call existing `Search::TextToEmbedding.call(phrase)` (Titan via `Aws::BedrockRuntime::Client`).
- Run with a small bounded parallelism.
- Keep embeddings in phrase order before calling `_msearch` so results line up with phrases (and keep per-phrase embedding failures separately).

2. Single OpenSearch batch request

- Call `Search::ChunkedContentRepository.new.msearch_by_embeddings(embeddings, max_chunks:)`
- Optionally pass `max_concurrent_searches:` to bound OpenSearch internal parallelism.

3. Rerank and filter per phrase

- Reuse `Search::ResultsForQuestion::Reranker.call(results)` and apply thresholds from `config/search.yml`.

Why this is safer

- Bedrock: stays on the AWS SDK path that already works with IRSA auth (no custom SigV4 signing) and keeps the same SDK-shaped errors our embedding code expects.
- OpenSearch: one HTTP request per retrieval, minimal socket pressure, no need to share OpenSearch client across threads.
- Failure handling is naturally per phrase because `msearch_by_embeddings` returns per-item statuses/errors (verified in specs).

Known trade-off

- Hybrid loses the cross-phrase pipelining that makes `bounded_pool`/`parallel_per_phrase` faster. We're trading ~25-30% latency (hybrid x2.71 vs bounded_pool x3.78) for simplicity. Do we want to talk to product/DS about whether this is reasonable?

---

## 6) Production safety controls

### Concurrency multiplication - grounded in real numbers

Main risk is nested concurrency:

`in flight ≈ pods × sidekiq concurrency × min(embedding_parallelism, phrase_count)`

With bounded embedding parallelism, phrase count does not multiply in-flight concurrency beyond the parallelism cap - per job, at most `EMBEDDING_PARALLELISM` embedding calls are in flight at once.

OpenSearch fan-out differs by approach:

- Hybrid: 1 `_msearch` request per job.
- Full per-phrase pipeline: up to `phrase_count` OpenSearch searches per job (and they can overlap across many jobs).

Our Sidekiq concurrency defaults to 10 per process (`config/sidekiq_answer.yml`). In production, `answer-worker` sets `SIDEKIQ_CONCURRENCY=25` via Helm values, and `govuk-chat-worker` can scale to 10 pods (HPA `maxReplicas: 10`).

Example worst-case with conservative defaults (`MAX_PHRASES=3`, `EMBEDDING_PARALLELISM=2`):

| Pods          | Sidekiq threads | Per-job max in-flight | Max bedrock embedding calls |
|---------------|-----------------|-----------------------|-----------------------------|
| 1             | 10              | 2                     | 20                          |
| 3             | 10              | 2                     | 60                          |
| 10 (prod max) | 25 (prod)       | 2                     | 500                         |

### Production guardrails

- Hard cap phrase fan‑out: `MAX_PHRASES = 3` (configurable, but clamped).
- Small embedding parallelism: `EMBEDDING_PARALLELISM = 2` (clamped to a small max e.g. 4).
- Per‑process semaphore around Bedrock invocations: ensures "max in‑flight Bedrock requests per process" is bounded even under Sidekiq load. This matters more than per-job pool size because it caps concurrency across all Sidekiq threads in the process.

### Authentication (Bedrock)

- Use IRSA + AWS SDK only for embeddings (current approach).
- Avoid manual SigV4 signing in app code.

### Failure modes / degradation

Per phrase:
- If an embedding fails: return an empty result set + error info for that phrase.
- If `_msearch` returns an error for one phrase: treat as empty for that phrase (do not fail the whole retrieval).

Whole request:
- If all phrases fail embedding: fall back to current single‑question retrieval (or return "no content found").

---

## 7) Why not async HTTP + manual SigV4

Pros:
The async signed Bedrock spike shows speed is achievable (x2.54 over sequential). It uses Typhoeus Hydra (libcurl multi) which does not spawn Ruby threads - concurrency is handled at the libcurl level. This avoids thread pool complexity concern.

However, productionising it means owning:
- SigV4 signing and credential refresh under IRSA (the spike snapshots credentials once, which is risky for long-lived Sidekiq processes)
- error handling beyond "non-2xx = failure" (we currently rely on AWS SDK exception types/messages for token limit truncation)
- retries/backoff (and deciding which failures are safe to retry)
- keeping monitoring and behaviour consistent, while adding a second Bedrock integration path alongside the AWS SDK

It also does not remove the request storm risk - we still have the same concurrency multiplication of in-flight network requests, just without Ruby threads managing them.

---

## 8) Observability

We already persist these metrics for the current single-phrase path (via `SearchResultFetcher` / `ResultsForQuestion`):

- duration
- embedding_duration
- search_duration
- reranking_duration
- embedding_provider

For multi-phrase retrieval, add/extend metrics so rollout decisions are quick and evidence-based:

- phrase_count
- embedding_parallelism (configured and effective)
- embedding_failures (count, and maybe a small breakdown by error class)
- msearch_item_failures (count, and maybe statuses)
- mode (hybrid vs current baseline), so pre/post comparisons are less noisy

---

## 9) Integration implications

Currently `SearchResultFetcher` calls `Search::ResultsForQuestion.call(question_message)` and expects a single flat `search_results` array. It aborts the pipeline with `unanswerable_no_govuk_content` if results are blank.

Moving to multi-phrase retrieval means:

- A new `Search::ResultsForPhrases` class returning per-phrase result sets + per-phrase errors.
- `SearchResultFetcher` (or a new pipeline step) needs to handle the per-phrase shape - either via a new context field (e.g. `context.search_result_sets`) or by flattening results before passing downstream.
- "Blank" semantics need defining: abort if all phrases return empty? Or only if a threshold of phrases fail?
- Merging/deduplication across phrases? Wasn't explored in the spike.

---

## 10) Low risk rollout idea

1. Ship hybrid behind a feature flag, with runtime config for:
   - `MAX_PHRASES`, `EMBEDDING_PARALLELISM`, and a per-process Bedrock semaphore.
2. Capture a baseline in each environment with the flag off (ideally a day of normal traffic).
3. Integration: enable 100% with conservative defaults:
   - `MAX_PHRASES=3`, `EMBEDDING_PARALLELISM=2`, small per-process Bedrock semaphore.
4. Staging: enable 100% and, if possible, test with production-like Sidekiq concurrency for the rollout window.
5. Production: canary first (small slice), then ramp up. Keep `EMBEDDING_PARALLELISM=2` at first.
6. Tuning: only increase parallelism after things look stable for a while. Try 3 in staging first, keep a hard max (e.g. 4), and back off on any throttling/timeout increase.

Go/no-go checks:

- error_* and `error_timeout` rate not up vs baseline
- Sidekiq answer queue age/backlog stable
- retrieval p95 (overall + embedding duration) stable or better
- no spike in Bedrock throttles or OpenSearch errors/timeouts

---

## 11) Next steps

- Implement a production‑ready `Search::ResultsForPhrases` that:
  - returns per-phrase result sets + per-phrase errors (preserving phrase order)
  - uses the hybrid shape described above
- Decide pool-per-job vs shared-pool approach
- Add per‑process Bedrock semaphore + conservative defaults
- Add the minimal metrics listed above
- Update `SearchResultFetcher` (or add a new pipeline step) to consume per-phrase results
- Run a load test simulating Sidekiq concurrency to validate:
  - error behaviour under throttle/timeouts
  - that global limiting prevents request storms
- (Optional): Extend the spike harness to report p95/p99 (and ideally embed vs OpenSearch time breakdown), so we can make the hybrid vs per-phrase trade-off with more confidence
