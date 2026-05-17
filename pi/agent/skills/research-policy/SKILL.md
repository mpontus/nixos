---
name: research-policy
description: Use for any response that can be grounded in external truth: current facts, documentation, package/API behavior, recommendations, comparisons, best practices, security/legal/pricing claims, disputed topics, or uncertainty. Prefer search/research before answering unless facts are purely local, user-provided, subjective/creative, or trivial stable knowledge.
---

# Research Policy

Use this skill whenever an answer can be improved by grounding factual claims in external truth.

Default posture: search before answering factual questions that depend on the world outside the current conversation or inspected files. Do not guess when a quick authoritative lookup would reduce risk.

## When to search

Use search/research tools before answering when the response includes:

- current facts, releases, package status, API behavior, or documentation details,
- recommendations, comparisons, package choices, best practices, or community consensus,
- security, compatibility, licensing, legal, pricing, or operational-risk claims,
- troubleshooting where versions, platforms, dependencies, or external services matter,
- facts that may be stale, disputed, or hard to verify from memory,
- any explicit request for sources, citations, verification, or confidence.

Skip search only when:

- the answer is grounded in local files, tests, command output, or user-provided content,
- the task is subjective, creative, stylistic, or preference-based,
- the fact is stable and trivial enough that lookup adds no value,
- the user asks not to use web/research,
- using external tools would expose secrets, credentials, proprietary code, or sensitive private context.

For local-code questions, inspect repo files/tests first. Use external docs only for dependency/API behavior, ecosystem norms, security advisories, or version-specific facts.

## Tool choice

- For quick lookup: use available web search/fetch tools.
- For recent news/events: prefer a news-oriented or timestamped source/tool when available.
- For recommendations, comparisons, package choices, best practices, or higher-stakes factual claims: prefer `gemini_research` when Gemini ACP is ready.
- For source discovery or lighter current lookup: use `gemini_search`, then verify important claims with primary sources or direct fetches.
- If Gemini-backed tools fail or appear unauthenticated, run `gemini_status` and report the blocker; fall back to available web search/fetch tools when useful.
- For code/library documentation: prefer primary docs, repositories, changelogs, release notes, and vendor advisories.
- For Pi package/config recommendations: inspect current setup first with `pi list` and relevant config files.

## Source quality

Prefer:

1. official docs and repositories,
2. release notes/changelogs,
3. maintainer posts, vendor advisories, or package pages,
4. reputable community discussions,
5. secondary articles only as supporting context.

Gemini ACP is useful for discovery and synthesis, but its source picks can be noisy or indirect. For security, package, incident, legal, pricing, or other high-stakes claims, verify Gemini findings against primary/vendor writeups, advisories, repositories, or direct fetched pages before acting.

For disputed topics, gather multiple sources and describe disagreements.

## Answer style

When research was used, summarize:

- answer or recommendation,
- sources consulted,
- confidence level,
- gaps/conflicts/unverified claims,
- practical next step.

Do not over-cite obvious local-file facts. Do cite external/current factual claims when possible.

## Pi configuration/package recommendations

Before recommending new Pi packages or global Pi behavior changes:

1. Inspect installed packages with `pi list`.
2. Inspect repo-managed config (`pi/agent/`) and deployed config (`~/.pi/agent/`) when relevant.
3. Prefer improving existing configuration over installing overlapping packages.
