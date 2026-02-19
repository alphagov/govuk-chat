# Concurrent Ruby Spike

## Benchmarks

Threaded spike results

5 phrases, 30 runs each, pool size 5:

| Strategy | P50 | Speedup |
|---|---|---|
| sequential | 0.926s | x1.00 |
| `bounded_pool` | 0.248s | x3.73 |
| `parallel_per_phrase` | 0.247s | x3.75 |
| `hybrid` | 0.321s | x2.89 |
| `msearch_only` | 0.652s | x1.42 |

3 phrases, 30 runs each, pool size 2:

| Strategy | P50 | Speedup |
|---|---|---|
| sequential | 0.543s | x1.00 |
| `bounded_pool` | 0.371s | x1.46 |
| `parallel_per_phrase` | 0.371s | x1.46 |
| `hybrid` | 0.319s | x1.70 |
| `msearch_only` | 0.402s | x1.35 |

Async HTTP signed Bedrock embedding spike (5 phrases, 5 runs):

- sequential avg 0.657s
- async avg 0.258s (x2.54)

Interpretation:

- Batching OpenSearch alone (`msearch_only`) is a meaningful improvement, but the biggest win comes from parallelising the Bedrock embedding calls.
- Full pipeline parallelism is fastest (`bounded_pool`, `parallel_per_phrase`) because it pipelines embedding and OpenSearch I/O across phrases - while phrase A is searching OpenSearch, phrase B is still embedding.
- Pool size changes the trade-off. At pool size 5, full pipeline parallelism is fastest. At pool size 2, hybrid is the fastest in this spike run (0.319s vs 0.371s/0.371s), while still keeping concurrency low.
- Hybrid is still a strong improvement (x1.70 over sequential at pool size 2) and trades some latency for operational simplicity (one OpenSearch request, no parallel OpenSearch calls).
- The async HTTP numbers are embeddings-only, so they are not directly comparable to the end-to-end threaded strategies.

---

## Ruby/Rails concurrency precedent

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
