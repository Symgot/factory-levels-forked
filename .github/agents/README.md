# .github Agent (summary / PR annotator)

Purpose:
- Keep a single, maintained summary of files under `.github/` and `docs/`.
- On PRs, post or update a single bot comment that summarizes the authoritative docs and provides quick verification hints.

How it works:
- The workflow runs on PR events and on pushes that affect `.github/**` or `docs/**`.
- When .github files change, a compact manifest JSON is (re)written to `.github/.agent_cache/manifest.json`.
- On PR runs, the agent posts/updates a single comment with the summary. This avoids producing many files per request.

Customizing:
- You can extend `agent.py` to perform stricter checks (e.g. ensure `Quellen / References` contains blob URLs with SHAs).
- Optionally turn the action into a Check Run instead of a comment.

Notes:
- This prototype is intentionally small. For production consider:
  - Better GitHub API error handling and rate limit handling.
  - Signing or verifying bot posts.
  - Running heavier NLP/analysis off‑repo or in a separate service.
