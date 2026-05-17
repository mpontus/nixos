---
name: research-policy
description: Use for web research, proactive search, current facts, recommendations, comparisons, package choices, best practices, external documentation, or disputed/version-dependent claims.
---

# Research Policy

Use this skill when a task depends on current, external, version-specific, community-practice, or disputed information.

## When to search

Consider using search/research tools when a quick lookup would ground the answer in reality, especially for:

- current facts, releases, package status, or API behavior,
- recommendations and comparisons,
- best practices or community consensus,
- external documentation,
- security, compatibility, licensing, or pricing claims,
- anything where memory may be stale or uncertain.

Do not guess when a quick authoritative lookup would reduce risk.

## Tool choice

- For quick lookup: use available web search/fetch tools.
- For recent news/events: prefer a news-oriented or timestamped source/tool when available.
- For recommendations, comparisons, package choices, best practices, or higher-stakes factual claims: prefer `gemini_research` when Gemini ACP is ready.
- For source discovery or lighter current lookup: use `gemini_search`, then verify important claims with primary sources or direct fetches.
- If Gemini-backed tools fail or appear unauthenticated, run `gemini_status` and report the blocker; fall back to available web search/fetch tools when useful.
- For code/library documentation: prefer primary docs, repositories, changelogs, and release notes.
- For Pi package/config recommendations: inspect current setup first with `pi list` and relevant config files.

## Source quality

Prefer:

1. official docs and repositories,
2. release notes/changelogs,
3. maintainer posts or package pages,
4. reputable community discussions,
5. secondary articles only as supporting context.

Gemini ACP is useful for discovery and synthesis, but its source picks can be noisy or indirect. For security, package, incident, legal, pricing, or other high-stakes claims, verify Gemini findings against primary/vendor writeups, advisories, repositories, or direct fetched pages before acting.

For disputed topics, gather multiple sources and describe disagreements.

## Answer style

When research was used, summarize:

- recommendation or answer,
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
4. Use advisor/reviewer guidance before strategic or global Pi configuration changes.
