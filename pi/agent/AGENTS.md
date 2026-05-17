# Global Pi instructions

## Working style

Prefer the smallest durable change that satisfies the request. Avoid broad rewrites, new frameworks, or extra tooling unless the user asks for them or repeated failures show they are needed.

When intent is ambiguous, resolve ambiguity before acting: ask a concise clarifying question, state a minimal assumption, or propose a small reversible patch.

## Research and web use

Default to grounding factual answers in truth. Use search/research tools before answering when the response makes current, external, version-specific, security-sensitive, legal, pricing, package/API/documentation, recommendation, comparison, best-practice, or disputed claims.

Skip search only when the answer is grounded in local files/tests/tool output, user-provided content, purely subjective or creative work, or stable trivial knowledge where lookup would add no value.

For recent news/events, prefer a news-oriented or timestamped source/tool when available.

Verify important claims with primary or reputable sources and mention uncertainty or gaps when relevant. Do not send secrets, credentials, or unnecessary private code to external research tools.

Before recommending new Pi packages or global Pi configuration changes, inspect the current Pi setup (`pi list`, relevant `~/.pi/agent` or repo-managed `pi/agent` files) and prefer improving existing setup over adding overlapping tools.
