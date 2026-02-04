# Performance Review

## Core Question
How does this behave at scale, and where are the bottlenecks?

## Scale Thinking

Code that works at 10 requests/second may fail at 10,000. Ask:
- What's the expected load now?
- What's the growth trajectory?
- Where will bottlenecks appear first?

## Common Performance Issues

### Data Access
- Queries that grow with data size (missing indexes, full scans)
- N+1 patterns (query per item in a loop)
- Fetching more data than needed
- Missing pagination on unbounded results
- Transactions held open too long

### Memory
- Unbounded collections without size limits
- Large objects held longer than necessary
- Accumulation over time without cleanup
- Loading entire datasets when streaming would work
- Resource leaks (connections, handles, buffers)

### Computation
- Repeated work that could be cached
- Unnecessary allocations in hot paths
- Blocking operations where async would work
- Missing early termination in searches
- Inefficient algorithms for the data size

### Concurrency
- Contention on shared resources
- Serial operations that could be parallel
- Unbounded parallelism without backpressure
- Missing coordination leading to thundering herd

## Complexity Analysis

For any loop or recursive operation:
- What's the time complexity?
- What's the space complexity?
- What's the realistic input size?
- Are there nested iterations that multiply?

Watch for:
- O(n²) or worse hiding in innocent-looking code
- Repeated work that could be memoized
- Linear scans where indexed lookup would work

## Caching Considerations

Before adding a cache:
- What's the invalidation strategy?
- What staleness is acceptable?
- What's the memory budget?
- What happens on cold start?
- Does this create thundering herd on expiry?

## Questions to Ask

- "What happens when input is 100x larger?"
- "What's the memory profile under sustained load?"
- "Is this CPU-bound, I/O-bound, or memory-bound?"
- "Where's the first bottleneck if we need to scale?"
- "What's the cost of this operation at expected load?"

## What Good Looks Like

- Bounded resource usage with explicit limits
- Appropriate algorithms for expected data sizes
- Lazy loading and pagination for large datasets
- Caching with clear invalidation strategy
- Performance characteristics documented or tested
